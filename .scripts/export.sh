export HISTSIZE=1000
export HISTFILESIZE=10000

export HISTCONTROL=ignoreboth
export HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

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
