_init() {
    _set_aliases
    alias ..="cd .."
    alias dl="cd ~/Downloads"

    if [ ! "$(type -t netstat)" == "" ]; then
        alias ports="netstat -tupln"
    fi
}
_set_alias_if_not_present() {
    if [ "$(type -t $1)" == "" ]; then
        alias $1="$2"
    fi
}

_set_aliases() {
    _set_alias_if_not_present "z" "zz"
    _set_alias_if_not_present "fd" "fdfind"
    _set_alias_if_not_present "ncdu" "gdu"
}


_init