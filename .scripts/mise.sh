_df_highest_git_repo() {
    if ! git rev-parse --show-toplevel 2>/dev/null 1>&2; then
        pwd
        return
    fi
    (
        local result="$(pwd)";
        while true; do
            local result2="$(git rev-parse --show-toplevel 2> /dev/null)"
            if [ "$result2" == "" ]; then
                echo "$result"
                return;
            fi
            result="$result2"
            builtin cd ..
        done
    )
}

if [ ! "$(type -t mise)" == "" ]; then
    dotlocation=""
    if [ -L ~/.do_not_delete ]; then
        dotlocation=$(dirname $(readlink -f ~/.do_not_delete))
    fi
    if [ ! "$dotlocation" == "" ]; then
        dotlocation="--allow-read ${dotlocation}/.pi"
    fi
    wsllocation=""
    if [ -d "/mnt/wsl" ]; then
        wsllocation="--allow-read /mnt/wsl"
    fi
    alias pi="mise x --deny-read --deny-write \
        $dotlocation $wsllocation \
        --allow-read ~/.local/share/mise \
        --allow-read ~/.local/bin \
        --allow-read ~/.config \
        --allow-read ~/.gitconfig \
        --allow-read ~/.cargo \
        --allow-write ~/.cache \
        --allow-write ~/.rustup \
        --allow-write ~/.cargo \
        --allow-write ~/.npm \
        --allow-write \$(_df_highest_git_repo) \
        --allow-write /tmp \
        --allow-write ~/.pi \
        pi -- pi"
    unset dotlocation
    unset wsllocation
fi
