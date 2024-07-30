zz(){
    
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
        if [ "$2" == "add" ]; then
            local line_number=$(grep -F -n "	$PWD	" "$DF_CD_CACHE_FILE" | cut -f1 -d:)
            if [ ! "$line_number" == "" ]; then
                local line=$(head -n $line_number "$DF_CD_CACHE_FILE" | tail -n 1)
                local count=$(echo $line | awk '{print $1}')
                local count=$(($count + 1))
                sed -i "${line_number}d" $DF_CD_CACHE_FILE
                echo -e "$count\t$PWD\t" >>$DF_CD_CACHE_FILE
            else
                echo -e "1\t$PWD\t" >>$DF_CD_CACHE_FILE
            fi
            return
        fi
    fi

    # default
    if cd $@ 2> /dev/null; then
        return
    fi
    
    local term="${1%/}"
    
    _df_search_dir() {
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
    if _df_search_dir "${_arr2[@]}"; then
        return
    fi
    
    echo "No path found"
    return 1
}

cc() {
    # default
    if cd $@ 2> /dev/null; then
        return
    fi

    return 1
}