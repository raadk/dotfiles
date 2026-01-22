#!/usr/bin/env bash
# Concatenate matching files, adding file-boundary headers
# Usage:
#   ./mdfiles.sh [--folders dir1 dir2 …] [--filetypes py js …] [--exclude dir1 dir2 …]
#               [--sep "#"|"="|beginend|xml] [--sep-len N]
#               [--output FILE | --exclude-stdout] [--zip FILE.zip]
#               [--list | --counts]

set -euo pipefail

declare -a skip_paths=()

# ---------------- argument parsing ----------------
folders=()
exts=()
excludes=( ".venv" )
list_only=false
count_only=false

# Separator style:
#   "#"        -> Markdown-style header:      ## path/to/file.ext
#   "="        -> One-line banner:            ====== path/to/file.ext ======
#   beginend   -> Explicit begin/end markers: ----- BEGIN FILE: ... / ----- END FILE: ...
#   xml        -> XML-ish wrapper:            <file path="..."> ... </file>
sep_style="beginend"
sep_len=6   # only used for "=" banner repeat count

# New output helpers
output_file=""            # write concat output directly to this file (avoids redirect loops)
zip_file=""               # create a zip archive of matched files (instead of concatenating)
exclude_stdout=false       # when enabled, auto-exclude the file connected to stdout (if any)

while [[ $# -gt 0 ]]; do
  case $1 in
    --folders)
      shift
      while [[ $# -gt 0 && $1 != --filetypes && $1 != --folders && $1 != --exclude && $1 != --sep && $1 != --sep-len && $1 != --output && $1 != --zip && $1 != --exclude-stdout && $1 != --list && $1 != --counts && $1 != --count && $1 != --help && $1 != -h ]]; do
        folders+=("$1"); shift
      done
      ;;
    --filetypes)
      shift
      while [[ $# -gt 0 && $1 != --folders && $1 != --filetypes && $1 != --exclude && $1 != --sep && $1 != --sep-len && $1 != --output && $1 != --zip && $1 != --exclude-stdout && $1 != --list && $1 != --counts && $1 != --count && $1 != --help && $1 != -h ]]; do
        exts+=("${1#.}"); shift
      done
      ;;
    --exclude)
      shift
      while [[ $# -gt 0 && $1 != --folders && $1 != --filetypes && $1 != --exclude && $1 != --sep && $1 != --sep-len && $1 != --output && $1 != --zip && $1 != --exclude-stdout && $1 != --list && $1 != --counts && $1 != --count && $1 != --help && $1 != -h ]]; do
        excludes+=("$1"); shift
      done
      ;;
    --sep)
      shift
      [[ $# -gt 0 ]] || { echo "Missing argument to --sep" >&2; exit 1; }
      sep_style="$1"
      shift
      ;;
    --sep-len)
      shift
      [[ $# -gt 0 ]] || { echo "Missing argument to --sep-len" >&2; exit 1; }
      sep_len="$1"
      shift
      ;;
    --output|-o)
      shift
      [[ $# -gt 0 ]] || { echo "Missing argument to --output" >&2; exit 1; }
      output_file="$1"
      shift
      ;;
    --exclude-stdout)
      exclude_stdout=true; shift
      ;;
    --zip)
      shift
      [[ $# -gt 0 ]] || { echo "Missing argument to --zip" >&2; exit 1; }
      zip_file="$1"
      shift
      ;;
    --list)
      list_only=true; shift
      ;;
    --counts|--count)
      count_only=true; shift
      ;;
    --help|-h)
      cat <<'EOF'
Usage: ./mdfiles.sh [--folders dir1 dir2 …] [--filetypes py js …] [--exclude dir1 dir2 …]
                   [--sep "#"|"="|beginend|xml] [--sep-len N]
                   [--output FILE | --exclude-stdout] [--zip FILE.zip]
                   [--list | --counts]

Modes (pick at most one):
  (default)         Concatenate matched files to stdout (or to --output FILE).
  --list            List matched file paths.
  --counts          Print per-file character counts + total.
  --zip FILE.zip    Create a zip archive containing all matched files.

Output-loop prevention:
  --exclude-stdout   If stdout is redirected to a regular file, automatically exclude
                     that file from the inputs (prevents infinite self-inclusion).
  --output FILE      Write concatenated output directly to FILE and auto-exclude it.

Separators (only used in concat mode; ignored for --list/--counts/--zip):
  --sep "#"         Markdown-style header:        ## path/to/file.ext
  --sep "="         One-line banner:              ====== path/to/file.ext ======
                    (repeat count controlled by --sep-len, default 6)
  --sep beginend    Explicit begin/end markers:   ----- BEGIN FILE: path ----- / ----- END FILE: path -----
  --sep xml         XML-ish wrapper:              <file path="..."> ... </file>

Examples:
  # Prevent the classic infinite loop when redirecting to a file inside the scanned tree
  ./mdfiles.sh --filetypes py md txt --exclude outputs .venv --exclude-stdout > Archive.md

  # Preferred: have the script write the output itself (also prevents loops)
  ./mdfiles.sh --filetypes py md txt --exclude outputs .venv --output Archive.md

  # Zip up the same selection of files
  ./mdfiles.sh --filetypes py md txt --exclude outputs .venv --zip Sources.zip
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# ---------------- mode validation ----------------
mode_count=0
$list_only && mode_count=$((mode_count + 1))
$count_only && mode_count=$((mode_count + 1))
[[ -n "$zip_file" ]] && mode_count=$((mode_count + 1))

if (( mode_count > 1 )); then
  echo "Only one of --list, --counts, or --zip can be used at a time." >&2
  exit 1
fi

if [[ -n "$output_file" && ( $list_only == true || $count_only == true || -n "$zip_file" ) ]]; then
  echo "--output can only be used in concat mode (no --list/--counts/--zip)." >&2
  exit 1
fi

[[ ${#folders[@]} -eq 0 ]] && folders=( . )

if [[ "$sep_style" == "=" ]]; then
  if ! [[ "$sep_len" =~ ^[0-9]+$ ]] || (( sep_len < 1 )); then
    echo "--sep-len must be a positive integer" >&2
    exit 1
  fi
fi

# ---------------- build the find expression ----------------
find_expr=()
if [[ ${#exts[@]} -gt 0 ]]; then
  find_expr+=( \( )
  for ext in "${exts[@]}"; do
    find_expr+=( -iname "*.$ext" -o )
  done
  find_expr=( "${find_expr[@]::${#find_expr[@]}-1}" )   # drop last -o
  find_expr+=( \) )
fi

# ---------------- choose a sort command ----------------
delimiter=$'\0'                        # assume we can stay NUL‑safe
if command -v gsort >/dev/null 2>&1; then
  sort_cmd=( gsort -z )                # Homebrew coreutils sort
elif sort -z </dev/null >/dev/null 2>&1; then
  sort_cmd=( sort -z )                 # GNU sort already in PATH
else
  sort_cmd=( sort )                    # BSD sort, no -z support
  delimiter=$'\n'                      # fall back to newline
fi

# If we can't do NUL-safe sort, we must also fall back to newline printing.
find_print=( -print0 )
if [[ "$delimiter" != $'\0' ]]; then
  find_print=( -print )
fi

# ---------------- separator emitters ----------------
emit_header() {
  local rel="$1"
  case "$sep_style" in
    "#"|md|markdown)
      echo "## $rel"
      ;;
    "="|eq|equals)
      local bar
      bar="$(printf '%*s' "$sep_len" '' | tr ' ' '=')"
      echo "${bar} ${rel} ${bar}"
      ;;
    beginend|be)
      echo "----- BEGIN FILE: $rel -----"
      ;;
    xml)
      printf '<file path="%s">\n' "$rel"
      ;;
    *)
      # Treat unknown values as a literal prefix (handy for custom tags)
      echo "${sep_style} $rel"
      ;;
  esac
}

emit_footer() {
  local rel="$1"
  case "$sep_style" in
    beginend|be)
      echo "----- END FILE: $rel -----"
      return 0
      ;;
    xml)
      echo "</file>"
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

emit_file() {
  local file="$1"
  local rel="${file#./}"

  emit_header "$rel"
  cat -- "$file"
  echo

  if emit_footer "$rel"; then
    echo
  fi
}

# ---------------- output-loop skip helpers ----------------
skip_paths=()

abspath() {
  local p="$1"
  if command -v realpath >/dev/null 2>&1; then
    realpath "$p"
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$p"
  else
    # Best-effort fallback (does not resolve symlinks reliably)
    local d b
    d="$(dirname -- "$p")"
    b="$(basename -- "$p")"
    (cd "$d" 2>/dev/null && printf '%s/%s\n' "$(pwd -P)" "$b") || printf '%s\n' "$p"
  fi
}

add_skip_path() {
  local p="$1"
  [[ -z "$p" ]] && return 0

  # Original
  skip_paths+=("$p")

  # Normalized relative variants
  if [[ "$p" != /* ]]; then
    local no_dot="${p#./}"
    skip_paths+=("$no_dot")
    skip_paths+=("./$no_dot")
  fi

  # Absolute variant
  local abs
  abs="$(abspath "$p" 2>/dev/null || true)"
  if [[ -n "$abs" ]]; then
    skip_paths+=("$abs")

    # If the absolute path is under CWD, add that relative form too.
    local cwd
    cwd="$(pwd -P)"
    if [[ "$abs" == "$cwd/"* ]]; then
      local rel="${abs#$cwd/}"
      skip_paths+=("$rel")
      skip_paths+=("./$rel")
    fi
  fi
}

should_skip() {
  local f="$1"
  local nf="${f#./}"
  local s ns
  for s in "${skip_paths[@]+"${skip_paths[@]}"}"; do
    ns="${s#./}"
    if [[ "$nf" == "$ns" ]]; then
      return 0
    fi
  done
  return 1
}

detect_stdout_path() {
  local target=""

  # Linux (procfs)
  if [[ -e "/proc/$$/fd/1" ]]; then
    target="$(readlink "/proc/$$/fd/1" 2>/dev/null || true)"
  fi

  # Some systems expose fd targets via /dev/fd
  if [[ -z "$target" && -e "/dev/fd/1" ]]; then
    target="$(readlink "/dev/fd/1" 2>/dev/null || true)"
  fi

  # macOS fallback: lsof tends to be available and reliable for this.
  if [[ -z "$target" ]] && command -v lsof >/dev/null 2>&1; then
    target="$(lsof -a -p $$ -d 1 -Fn 2>/dev/null | sed -n 's/^n//p' | head -n 1)"
  fi

  # Only return regular files (pipes/sockets/ttys don't help)
  if [[ -n "$target" && -f "$target" ]]; then
    printf '%s\n' "$target"
  fi
}

# Build skip set
if [[ -n "$output_file" ]]; then
  add_skip_path "$output_file"
fi
if [[ -n "$zip_file" ]]; then
  add_skip_path "$zip_file"
fi
if $exclude_stdout; then
  stdout_path="$(detect_stdout_path || true)"
  if [[ -n "$stdout_path" ]]; then
    add_skip_path "$stdout_path"
  fi
fi

# If requested, write output directly to a file (concat mode only).
if [[ -n "$output_file" ]]; then
  out_dir="$(dirname -- "$output_file")"
  if [[ "$out_dir" != "." ]]; then
    mkdir -p -- "$out_dir"
  fi
  # Truncate/create and redirect stdout
  exec > "$output_file"
fi

# ---------------- main pipeline ----------------
{
  for dir in "${folders[@]}"; do
    exclude_expr=()
    if [[ ${#excludes[@]} -gt 0 ]]; then
      exclude_expr+=( \( )
      for excl in "${excludes[@]}"; do
        if [[ $excl == /* ]]; then
          exclude_expr+=( -path "$excl" -o -path "$excl/*" -o )
        else
          exclude_expr+=( -path "$dir/$excl" -o -path "$dir/$excl/*" -o )
        fi
      done
      exclude_expr=( "${exclude_expr[@]::${#exclude_expr[@]}-1}" )   # drop last -o
      exclude_expr+=( \) -prune -o )
    fi

    if [[ ${#find_expr[@]} -gt 0 ]]; then
      find "$dir" "${exclude_expr[@]}" -type f "${find_expr[@]}" "${find_print[@]}" 2>/dev/null
    else
      find "$dir" "${exclude_expr[@]}" -type f "${find_print[@]}" 2>/dev/null
    fi
  done
} | "${sort_cmd[@]}" | \
if [[ $delimiter == $'\0' ]]; then
  if $count_only; then
    total=0
    while IFS= read -r -d '' file; do
      should_skip "$file" && continue
      count=$(wc -m < "$file" | tr -d '[:space:]')
      echo "$count ${file#./}"
      total=$((total + count))
    done
    echo "TOTAL $total"
  elif $list_only; then
    while IFS= read -r -d '' file; do
      should_skip "$file" && continue
      echo "${file#./}"
    done
  elif [[ -n "$zip_file" ]]; then
    command -v zip >/dev/null 2>&1 || { echo "zip command not found (needed for --zip)" >&2; exit 1; }

    tmp="$(mktemp)"
    trap 'rm -f "$tmp"' EXIT

    n=0
    while IFS= read -r -d '' file; do
      should_skip "$file" && continue
      printf '%s\n' "${file#./}" >> "$tmp"
      n=$((n + 1))
    done

    if (( n == 0 )); then
      echo "No matching files to zip." >&2
      exit 1
    fi

    zip_dir="$(dirname -- "$zip_file")"
    if [[ "$zip_dir" != "." ]]; then
      mkdir -p -- "$zip_dir"
    fi

    rm -f -- "$zip_file"

    # -@ reads file names (one per line) from stdin.
    zip -q "$zip_file" -@ < "$tmp"

    echo "Wrote $zip_file ($n files)" >&2
  else
    while IFS= read -r -d '' file; do
      should_skip "$file" && continue
      emit_file "$file"
    done
  fi
else
  if $count_only; then
    total=0
    while IFS= read -r file; do
      should_skip "$file" && continue
      count=$(wc -m < "$file" | tr -d '[:space:]')
      echo "$count ${file#./}"
      total=$((total + count))
    done
    echo "TOTAL $total"
  elif $list_only; then
    while IFS= read -r file; do
      should_skip "$file" && continue
      echo "${file#./}"
    done
  elif [[ -n "$zip_file" ]]; then
    command -v zip >/dev/null 2>&1 || { echo "zip command not found (needed for --zip)" >&2; exit 1; }

    tmp="$(mktemp)"
    trap 'rm -f "$tmp"' EXIT

    n=0
    while IFS= read -r file; do
      should_skip "$file" && continue
      printf '%s\n' "${file#./}" >> "$tmp"
      n=$((n + 1))
    done

    if (( n == 0 )); then
      echo "No matching files to zip." >&2
      exit 1
    fi

    zip_dir="$(dirname -- "$zip_file")"
    if [[ "$zip_dir" != "." ]]; then
      mkdir -p -- "$zip_dir"
    fi

    rm -f -- "$zip_file"

    zip -q "$zip_file" -@ < "$tmp"

    echo "Wrote $zip_file ($n files)" >&2
  else
    while IFS= read -r file; do
      should_skip "$file" && continue
      emit_file "$file"
    done
  fi
fi
