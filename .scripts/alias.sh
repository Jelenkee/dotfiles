if [ "$(type -t z)" == "" ]; then
    alias z="zz"
fi

up() {
    if [ ! "$(type -t pacman)" == "" ]; then
        cmd="pacman -Syu"
        elif [ ! "$(type -t apt)" == "" ]; then
        cmd="bash -c 'apt update && apt upgrade'"
    else
        echo "System not supported"
        return 1;
    fi
    
    local id=$(id -u)
    if [ ! "$id" == "0" ]; then
        cmd="sudo $cmd"
    fi
    bash -c "$cmd"
}

deps() {
    up
    _install_package "fd"
    _install_package "fd-find"
    if [ ! "$(type -t fdfind)" == "" ]; then
        alias fd="fdfind"
    fi
    _install_package "micro"
    _install_package "gdu"
    if [ "$(type -t ncdu)" == "" ]; then
        alias ncdu="gdu"
    fi
}

zz() {
    # subcommands
    if [ "$1" == "--" ];then
        if [ "$2" == "list" ];then
            cat $DF_CD_CACHE_FILE | sort -nr
            return
        fi
        if [ "$2" == "clear" ];then
            rm $DF_CD_CACHE_FILE
            touch $DF_CD_CACHE_FILE
            return
        fi
    fi

    # special cases
    if [ "$1" == "" ];then
        cd
        return
    fi
    if [ "$1" == "~" ];then
        cd $HOME
        return
    fi
    local special_values="- . .."
    if echo $special_values | grep -F -q -w $1 ;then
        cd "$1"
        return
    fi
    
    # correct path
    if [ -d "$1" ]; then
        cd "$1"
        return
    fi
    
    local term=$1
    
    _search_dir() {
        local dirs=$1
        for dir in $dirs; do
            local bdir=$(basename $dir)
            if [ "${bdir,,}" == "${term,,}" ];then
                cd $dir
                return
            fi
        done
        for dir in $dirs; do
            if echo "$(basename $dir)" | grep -F -q -i $term ;then
                cd $dir
                return
            fi
        done
        
        return 1
    }
    
    # cached dirs
    if _search_dir "$(cat $DF_CD_CACHE_FILE | sort -nr | awk '{print $2}')"; then
        return
    fi
    
    # local dirs
    if _search_dir "$(find $PWD -maxdepth 1 -type d | grep -F -i $term)"; then
        return
    fi
    
    # nested dirs
    local depth="${DF_Z_HOME_DEPTH:-5}"
    if [ ! "$depth" == "0" ] && _search_dir "$(find $HOME -maxdepth $depth -type d | grep -F -i $term | awk '{ print length, $0 }' | sort -n -s | cut -d" " -f2-)"; then
        return
    fi
    
    echo "No path found"
    return 1
    
}

erase() {
    set -x
    rm -rf ~/.cache
    rm -rf ~/.local/share/Trash/*
    rm -rf ~/.cargo/registry/src
    rm -rf ~/.cargo/registry/cache
    set +x
    if [ ! "$(type -t cargo)" == "" ]; then
        for f in $(find ~ -name "Cargo.toml"); do
            cargo clean --manifest-path $f
            cargo clean -r --manifest-path $f
        done
    fi
    if [ ! "$(type -t pacman)" == "" ]; then
        sudo pacman -Sc
        elif [ ! "$(type -t apt)" == "" ]; then
        sudo apt autoremove
        sudo apt clean
    fi
}

_install_package() {
    echo "$#"
    echo "$0"
    echo "$1"
    echo "$2"
    if [ ! "$(type -t pacman)" == "" ]; then
        cmd="sudo pacman -S --noconfirm $1"
        elif [ ! "$(type -t apt)" == "" ]; then
        cmd="sudo apt -y install $1"
    else
        echo "System not supported"
        return 1;
    fi
    bash -c "$cmd"
}

