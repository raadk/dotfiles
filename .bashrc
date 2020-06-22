alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias dudir="du -sh * | sort -hr"
alias c="clear"

export PROJECTS="#"
export COURSES="$PROJECTS/courses"
export DATA="#"
export NOTES="#"

alias lsd="ls -alhF | grep /$"
alias diskspace="du -Sh | sort -n -r |more"
alias folders="find . -maxdepth 1 -type d -print | xargs du -skh | sort -rn"
alias mostused='history | awk '\''{CMD[$2]++;count++;}END { for (a in CMD)print CMD[a] " " CMD[a]/count*100 "% " a;}'\'' | grep -v "./" | column -c3 -s " " -t | sort -nr | nl ' # |  head -n10'

alias vimrc="vim ~/.vimrc"
alias bashrc="vim ~/.bashrc"


cdls() { cd "$@" && ls; }

project() { cd "$PROJECTS/$@"; }
projects() { ls -lht "$PROJECTS/"; }

note() { vim "$NOTES/$@.md"; }
notes() { ls -lht "$NOTES"; }

course() { cd "$COURSES/$@"; }
courses() { ls -lht "$COURSES/"; }
