mkd() {
    mkdir -p "$@" && cd "$_"
}

up() {
    if [ ! "$(type -t yay)" == "" ]; then
        yay
    elif [ ! "$(type -t pacman)" == "" ]; then
        sudo pacman -Syu
    elif [ ! "$(type -t apt)" == "" ]; then
        sudo apt update && sudo apt upgrade
        sudo apt autoremove
    else
        echo "System not supported"
        return 1
    fi

    if [ ! "$(type -t rustup)" == "" ]; then
        rustup update stable
    fi

    if [ ! "$(type -t deno)" == "" ]; then
        deno upgrade
    fi
}

deps() {
    up
    _install_package "fd"
    _install_package "fd-find"
    _install_package "micro"
    _install_package "gdu"
    _install_package "lsof"

    if [ ! "$(type -t _set_aliases)" == "" ]; then
        _set_aliases
    fi
}

edit() {
    eval $EDITOR $@
}

ebrc() {
    eval $EDITOR ~/.bashrc
}

serve() {
    local port="${1:-9000}"
    if [ ! "$(type -t python3)" == "" ]; then
        python3 -m http.server $port
    elif [ ! "$(type -t php)" == "" ]; then
        php -S localhost:$port
    elif [ ! "$(type -t npx)" == "" ]; then
        npx --yes serve --listen $port
    fi
    
}

pwgen() {
    local len="${1:-16}"
    local number="${2:-1}"
    local double=$(($len + $len))
    for (( i=0; i<$number; i++ ))
    do
        head -c "$double" < /dev/urandom | base64 -w 0 | tr -d "=+/" | head -c "$len"
        echo ""
    done
}

search() {
    find $PWD -iname "*${1}*" -type f
}

searchd() {
    find $PWD -iname "*${1}*" -type d
}

zup() {
    local steps=${1:-1}
    local cmd=""
    for ((i = 0; i < $steps; i++)); do
        cmd+="../"
    done

    builtin cd $cmd
}

erase() {
    rm -rf ~/.cache/*
    rm -rf ~/.local/share/Trash/*
    rm -rf ~/.cargo/registry/src
    rm -rf ~/.cargo/registry/cache
    if [ ! "$(type -t cargo)" == "" ]; then
        find ~ -path ~/.rustup -prune -o -path ~/.cargo -prune -o -name 'Cargo.toml' -exec cargo clean --manifest-path {} \; -exec cargo clean -r --manifest-path {} \;
    fi
    if [ ! "$(type -t pacman)" == "" ]; then
        sudo pacman -Rcs $(pacman -Qdtq)
        sudo pacman -Sc
    elif [ ! "$(type -t apt)" == "" ]; then
        sudo apt autoremove
        sudo apt clean
    fi
    if [ ! "$(type -t docker)" == "" ]; then
        sudo docker image prune -f
    fi
}

upload() {
    local title=""
    if [ ! "$1" == "" ]; then
        local text=$(cat $1)
        local title=$(basename $1)
    else
        local text=$(cat)
    fi
    if [ "$text" == "" ]; then
        echo "no text"
        return
    fi
    local url=$(curl -v 'https://paste.centos.org/' -X POST -H 'Content-Type: application/x-www-form-urlencoded' --data-urlencode "name=$USER" --data-urlencode "title=$title" --data-urlencode "lang=text" --data-urlencode "code=$text" --data-urlencode "expire=1440" --data-urlencode "submit=submit" 2>&1 | grep -iF "location: " | grep -o "https.*")
    echo $url
    echo $url | sed 's#/view#/view/raw#'
}

gsw() {
    if [ "$1" == "" ]; then
        echo "Missing argument"
        return 1
    fi

    local branch=$(git branch -l --format "%(refname:short)" | grep -F -i "$1")

    if [ "$branch" == "" ]; then
        echo "No branch found"
        return 1
    fi

    git switch $branch
}

killport() {
    if [ "$1" == "" ]; then
        echo "Missing argument"
        return 1
    fi

    local pid=$(lsof -i :$1 | grep -w -i -F tcp | awk '{print $2}')
    
    if [ "$pid" == "" ]; then
        echo "No PID found"
        return 1
    fi

    kill $pid

    local pid2=$(lsof -i :$1 | grep -w -i -F tcp | awk '{print $2}')

    if [ ! "$pid2" == "" ]; then
        sleep 1
        kill -9 $pid2
    fi    
}

_install_package() {
    if [ ! "$(type -t pacman)" == "" ]; then
        sudo pacman -S --noconfirm "$1"
    elif [ ! "$(type -t apt)" == "" ]; then
        sudo apt -y install "$1"
    else
        echo "System not supported"
        return 1
    fi
}

paths() {
    echo $PATH | tr ':' '\n' | sort | uniq
}

if [ ! "$(type -t docker)" == "" ]; then
    dokk_exec() {
        if [ "$1" == "" ]; then
            echo "Missing argument"
            return 1
        fi
        docker ps > /dev/null
        docker exec -it $1 /bin/bash || docker exec -it $1 /bin/sh
    }

    _df_comp_dokk_exec() {
        local cur prev;
        cur="${COMP_WORDS[COMP_CWORD]}";
        prev="${COMP_WORDS[COMP_CWORD-1]}";
        COMPREPLY=()
        if [ "$prev" == "dokk_exec" ]; then
            COMPREPLY=( $(compgen -W "$(docker ps --format '{{.Names}}')" -- ${cur}) )
        fi
    }
    
    complete -F _df_comp_dokk_exec dokk_exec
fi
