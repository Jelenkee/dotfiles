_df_init() {
    _set_alias_if_not_present "z" "zz"
    _set_alias_if_not_present "fd" "fdfind"
    _set_alias_if_not_present "ncdu" "gdu"
    _set_alias_if_not_present ".." "cd .."
    _set_alias_if_not_present "..." "cd ../.."
    _set_alias_if_not_present "cd-" "cd -"
    _set_alias_if_not_present "dl" "cd ~/Downloads"
    _set_alias_if_not_present "ranger" "yazi"
    _set_alias_if_not_present "y" "yazi"
    _set_alias_if_not_present "fetch" "ffetch"

    if [ ! "$(type -t netstat)" == "" ]; then
        alias ports="netstat -tupln"
    elif [ ! "$(type -t ss)" == "" ]; then
        alias ports="ss -tlpn"
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
    alias eecho="echo \"\$@\" 1>&2"
    alias ll="ls -lA"
    alias lisa="ls -lisa"
    alias sl="ls"
    alias l="ls"
    alias cdtmp="cd \$(mktemp -d)"

    git config --global alias.s 'status -s'
    git config --global alias.pul 'pull'
    git config --global alias.pus 'push'
    git config --global push.autoSetupRemote true
    if [ ! "$(type -t micro)" == "" ]; then
        git config --global core.editor micro
    fi

}
_set_alias_if_not_present() {
    if [ "$(type -t $1)" == "" ]; then
        alias $1="$2"
    fi
}

_df_init
