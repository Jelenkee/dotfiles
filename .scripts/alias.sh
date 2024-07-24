_init() {
    _set_alias_if_not_present "z" "zz"
    _set_alias_if_not_present "fd" "fdfind"
    _set_alias_if_not_present "ncdu" "gdu"
    _set_alias_if_not_present ".." "cd .."
    _set_alias_if_not_present "dl" "cd ~/Downloads"

    if [ ! "$(type -t netstat)" == "" ]; then
        alias ports="netstat -tupln"
    fi

    if [ -x /usr/bin/dircolors ]; then
        test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
        alias ls='ls --color=auto'

        alias grep='grep --color=auto'
        alias fgrep='fgrep --color=auto'
        alias egrep='egrep --color=auto'
    fi

    alias g="git"
    alias push="git push --set-upstream origin \$(git rev-parse --abbrev-ref HEAD)"
    alias sudo="sudo "

}
_set_alias_if_not_present() {
    if [ "$(type -t $1)" == "" ]; then
        alias $1="$2"
    fi
}

_init
