if [ ! "$(type -t mise)" == "" ]; then
    dotlocation=""
    if [ -L ~/.do_not_delete ]; then
        dotlocation=$(dirname $(readlink -f ~/.do_not_delete))
    fi
    if [ ! "$dotlocation" == "" ]; then
        dotlocation="--allow-read ${dotlocation}/.pi"
    fi
    alias pi="mise x --deny-read --deny-write $dotlocation --allow-read ~/.local/share/mise --allow-write \$PWD --allow-write /tmp --allow-write ~/.pi pi -- pi"
    unset dotlocation
fi