__local_bin="$HOME/._df/bin"
if ! echo "$PATH" | grep -q -F "$__local_bin"; then
    PATH="${PATH}:${__local_bin}"
fi
unset __local_bin

export HISTSIZE=1000
export HISTFILESIZE=10000

export HISTCONTROL=ignoreboth
export HISTIGNORE="&:[ ]*:exit:clear"

__lc=$(locale -a | grep -E -i "^en_us\.utf.+$" | head -n 1)
if [ ! "$__lc" == "" ]; then
    export LANG=$__lc
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
#shopt -s cdspell
#shopt -s cmdhist
