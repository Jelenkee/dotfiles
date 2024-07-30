mkd() {
    mkdir -p "$@" && cd "$_"
}

up() {
    if [ ! "$(type -t yay)" == "" ]; then
        local cmd="yay"
    elif [ ! "$(type -t pacman)" == "" ]; then
        local cmd="sudo pacman -Syu"
    elif [ ! "$(type -t apt)" == "" ]; then
        local cmd="sudo apt update && sudo apt upgrade"
    else
        echo "System not supported"
        return 1
    fi

    bash -c "$cmd"
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
    python3 -m http.server $port
}

pwgen() {
    local len="${1:-16}"
    local double=$(($len + $len))
    head -c "$double" < /dev/urandom | base64 -w 0 | tr -d "=+/" | head -c "$len"
    echo ""
}

search() {
    find $PWD -iname "*${1}*" -type f
}

searchd() {
    find $PWD -iname "*${1}*" -type d
}

zz() {
    # subcommands
    if [ "$1" == "--" ]; then
        if [ "$2" == "list" ]; then
            cat $DF_CD_CACHE_FILE | sort -nr
            return
        fi
        if [ "$2" == "clear" ]; then
            rm $DF_CD_CACHE_FILE
            touch $DF_CD_CACHE_FILE
            return
        fi
        if [ "$2" == "remove" ]; then
            local dir="$3"
            if [ "$dir" == "" ]; then
                local dir="$PWD"
            fi
            # TODO
            return
        fi
    fi

    # special cases
    if [ "$1" == "" ] || [ "$1" == "~" ]; then
        cd
        return
    fi
    local special_values="- . .."
    if echo $special_values | grep -F -q -w $1; then
        cd "$1"
        return
    fi

    # correct path
    if [ -d "$1" ]; then
        cd "$1"
        return
    fi

    # short path
    local term="${1%/}"
    : 'local first_char="${term:0:1}"
    local term="${term#/}"
    local term="${term,,}"

    _match_path() {
        local real_path=$1
        echo "r $real_path" | grep -i downl
        local real_path_lower="${real_path,,}"
        IFS="/" read -r -a real_parts <<< "${real_path_lower#/}"
        local success=true
        for i in "${!real_parts[@]}";do
            local rbit="${real_parts[$i]}"
            local tbit="${term_parts[$i]}"
            if [[ ! "$rbit" == "$tbit"* ]];then
                local success=false
            fi
        done
        if [ "$success" == true ];then
            echo $real_path
        fi
    }

    if [ "$first_char" == "/" ];then
        echo "terminus $term"
        local part_count=$(($(grep -o "/" <<< "$term" | wc -l )+1))
        IFS="/" read -r -a term_parts <<< "$term"
        echo "count $part_count"
        #find $(cd /; pwd) -maxdepth $part_count -mindepth $part_count -type d -exec match_path {} \; 2> /dev/null
        find $(cd /; pwd) -maxdepth $part_count -mindepth $part_count -type d 2> /dev/null | while read dir; do
        local match=$(_match_path "$dir");
        if [ ! "$match" == "" ];then
            cd $match;
            return;
        fi
        done
        
    else
        echo "term $term"
        local part_count=$(($(grep -o "/" <<< "$term" | wc -l )+1))
        IFS="/" read -r -a term_parts <<< "$term"
        echo "count $part_count"
        local paths=$(find $(cd .; pwd) -maxdepth $part_count -mindepth $part_count -type d 2> /dev/null)
        #echo "dsd $paths"
        for real_path in $paths; do
            echo "rela $real_path"
            local real_path_lower="${real_path,,}"
            IFS="/" read -r -a real_parts <<< "${real_path_lower#/}"
            local success=true
            for i in "${!real_parts[@]}";do
                local rbit="${real_parts[$i]}"
                local tbit="${term_parts[$i]}"
                if [[ ! "$rbit" == "$tbit"* ]];then
                    local success=false
                fi
            done
            if [ "$success" == true ];then
                cd $real_path
                return
            fi
        done
    fi'

    _search_dir() {
        local dirs=("$@")
        for dir in "${dirs[@]}"; do
            local bdir=$(basename "$dir")
            if [ "${bdir,,}" == "${term,,}" ]; then
                if [ -d "$dir" ]; then
                    cd "$dir"
                    return
                fi
            fi
        done
        for dir in "${dirs[@]}"; do
            if echo $(basename "$dir") | grep -F -q -i "$term"; then
                if [ -d "$dir" ]; then
                    cd "$dir"
                    return
                fi
            fi
        done

        return 1
    }

    local _arr2

    # cached dirs
    readarray -t _arr2 < <(cat $DF_CD_CACHE_FILE | sort -nr | awk -F '\t' '{print $2}')
    if _search_dir "${_arr2[@]}"; then
        return
    fi

    # local dirs
    readarray -t _arr2 < <(find $PWD -maxdepth 1 -type d)
    if _search_dir "${_arr2[@]}"; then
        return
    fi

    # nested dirs
    : 'local depth="${DF_Z_HOME_DEPTH:-5}"
    if [ ! "$depth" == "0" ] && _search_dir "$(find $HOME -maxdepth $depth -type d | grep -F -i "$term" | awk '{ print length, $0 }' | sort -n -s | cut -d" " -f2-)"; then
        return
    fi'

    echo "No path found"
    return 1

}

zup() {
    local steps=${1:-1}
    local cmd=""
    for ((i = 0; i < $steps; i++)); do
        cmd+="../"
    done

    cd $cmd
}

erase() {
    set -x
    rm -rf ~/.cache
    rm -rf ~/.local/share/Trash/*
    rm -rf ~/.cargo/registry/src
    rm -rf ~/.cargo/registry/cache
    set +x
    if [ ! "$(type -t cargo)" == "" ]; then
        find ~ -name "Cargo.toml" -exec cargo clean --manifest-path {} \; -exec cargo clean -r --manifest-path {} \;
    fi
    if [ ! "$(type -t pacman)" == "" ]; then
        sudo pacman -Sc
    elif [ ! "$(type -t apt)" == "" ]; then
        sudo apt autoremove
        sudo apt clean
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

    eval git switch $branch
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
        local cmd="sudo pacman -S --noconfirm $1"
    elif [ ! "$(type -t apt)" == "" ]; then
        local cmd="sudo apt -y install $1"
    else
        echo "System not supported"
        return 1
    fi
    bash -c "$cmd"
}
