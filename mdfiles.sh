#!/usr/bin/env bash
# Concatenate matching files, adding file-boundary headers
# Usage:
#   ./mdfiles.sh [--folders dir1 dir2 …] [--filetypes py js …] [--exclude dir1 dir2 …]
#               [--sep "#"|"="|beginend|xml] [--sep-len N]
#               [--list | --counts]

set -euo pipefail

# ---------------- argument parsing ----------------
folders=()
exts=()
excludes=( ".venv" )
list_only=false
count_only=false

# Separator style:
#   "#"        -> Markdown-style header:      ## path/to/file.ext   (default)
#   "="        -> One-line banner:            ====== path/to/file.ext ======
#   beginend   -> Explicit begin/end markers: ----- BEGIN FILE: ... / ----- END FILE: ...
#   xml        -> XML-ish wrapper:            <file path="..."> ... </file>
sep_style="beginend"
sep_len=6   # only used for "=" banner repeat count

while [[ $# -gt 0 ]]; do
  case $1 in
    --folders)
      shift
      while [[ $# -gt 0 && $1 != --filetypes && $1 != --folders && $1 != --exclude && $1 != --sep && $1 != --sep-len && $1 != --list && $1 != --counts && $1 != --count && $1 != --help && $1 != -h ]]; do
        folders+=("$1"); shift
      done
      ;;
    --filetypes)
      shift
      while [[ $# -gt 0 && $1 != --folders && $1 != --filetypes && $1 != --exclude && $1 != --sep && $1 != --sep-len && $1 != --list && $1 != --counts && $1 != --count && $1 != --help && $1 != -h ]]; do
        exts+=("${1#.}"); shift
      done
      ;;
    --exclude)
      shift
      while [[ $# -gt 0 && $1 != --folders && $1 != --filetypes && $1 != --exclude && $1 != --sep && $1 != --sep-len && $1 != --list && $1 != --counts && $1 != --count && $1 != --help && $1 != -h ]]; do
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
                   [--list | --counts]

Separators (only used in concat mode; ignored for --list/--counts):
  --sep "#"         Markdown-style header:        ## path/to/file.ext        (default)
  --sep "="         One-line banner:              ====== path/to/file.ext ======
                    (repeat count controlled by --sep-len, default 6)
  --sep beginend    Explicit begin/end markers:   ----- BEGIN FILE: path ----- / ----- END FILE: path -----
  --sep xml         XML-ish wrapper:              <file path="..."> ... </file>

Examples:
  ./mdfiles.sh --filetypes py js --exclude node_modules dist --sep "=" --sep-len 10
  ./mdfiles.sh --folders src tests --sep beginend
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if $list_only && $count_only; then
  echo "Only one of --list or --counts can be used at a time." >&2
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
      count=$(wc -m < "$file" | tr -d '[:space:]')
      echo "$count ${file#./}"
      total=$((total + count))
    done
    echo "TOTAL $total"
  elif $list_only; then
    while IFS= read -r -d '' file; do
      echo "${file#./}"
    done
  else
    while IFS= read -r -d '' file; do
      emit_file "$file"
    done
  fi
else
  if $count_only; then
    total=0
    while IFS= read -r file; do
      count=$(wc -m < "$file" | tr -d '[:space:]')
      echo "$count ${file#./}"
      total=$((total + count))
    done
    echo "TOTAL $total"
  elif $list_only; then
    while IFS= read -r file; do
      echo "${file#./}"
    done
  else
    while IFS= read -r file; do
      emit_file "$file"
    done
  fi
fi

