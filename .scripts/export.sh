export HISTSIZE=1000
export HISTFILESIZE=10000

export HISTCONTROL=ignoreboth
export HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"

export LANG=en_US.UTF-8
__lc=$(locale -a | grep -E -i "^en_\w\w\.utf.+$")
if [ ! "$__lc" == "" ]; then
    export LC_ALL=$__lc
fi
unset __lc

if [ ! "$(type -t micro)" == "" ]; then
    export EDITOR=micro
    export VISUAL=micro
else
    export EDITOR=nano
    export VISUAL=nano
fi

export CLICOLOR=1

shopt -s histappend
shopt -s checkwinsize
shopt -s cdspell
#shopt -s cmdhist
