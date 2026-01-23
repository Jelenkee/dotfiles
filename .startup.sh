filename="/tmp/aJ4ch1hJux6CCtRu"
if [ -f "$filename" ]; then
    return
fi
touch "$filename"
unset filename

# download nano syntax
nano_dirr="$HOME/.nano/syntax"
if [ ! -d "${nano_dirr}" ]; then
    mkdir -p "$(dirname "${nano_dirr}")"
    if [ ! -d "/usr/share/nano-syntax-highlighting" ]; then
        git clone https://github.com/scopatz/nanorc.git "${nano_dirr}"
    else
        ln -s "/usr/share/nano-syntax-highlighting" "${nano_dirr}"
    fi
fi
unset nano_dirr

# set git config
if [ ! "$(type -t git)" == "" ]; then
    git config --global alias.s 'status -s'
    git config --global alias.pul 'pull'
    git config --global alias.pus 'push'
    git config --global push.autoSetupRemote true
    git config --global core.editor nano
fi
