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
                dir="$PWD"
            fi
            local line_number=$(grep -F -n "	$dir	" "$DF_CD_CACHE_FILE" | cut -f1 -d:)
            if [ ! "$line_number" == "" ]; then
                sed -i "${line_number}d" $DF_CD_CACHE_FILE
            fi
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
    if builtin cd $@ 2> /dev/null; then
        return
    fi
    
    local args=("$@")
    local _arr2
    
    readarray -t _arr2 < <(cat $DF_CD_CACHE_FILE | sort -nr | awk -F '\t' '{print $2}')
    if _df_search_dir _arr2[@] args[@]; then
        return
    fi
    
    echo "No path found"
    return 1
}

cd() {
    # default
    if builtin cd $@ 2> /dev/null; then
        return
    fi

    local args=("$@")
    local last_arg="${args[-1]}"
    local len=${#args[@]}
    local plus_len=$((len + 1))

    local _arr2

    readarray -t -d '' _arr2 < <(find . -mindepth $len -maxdepth $plus_len -type d -iname "*${last_arg}*" -print0)
    local sorted_array=($(printf "%s\n" "${_arr2[@]}" | awk '{ print length, $0 }' | sort -n | cut -d' ' -f2-))
    printf "%s\n" "${sorted_array[@]}"
    if _df_search_dir sorted_array[@] args[@]; then
        return
    fi
    
    return 1
}

_df_search_dir() {
    local dirs=("${!1}")
    local terms=("${!2}")

    for dir in "${dirs[@]}"; do
        local match=true
        local last_term="${terms[-1]}"
        if ! echo $(basename "$dir") | grep -F -q -i "$last_term"; then
            match=false
            continue
        fi

        local len=${#terms[@]}
        local pre_terms=("${terms[@]:0:$((len - 1))}")

        for term in "${pre_terms[@]}"; do
            if ! echo "$dir" | grep -F -q -i "$term"; then
                match=false
                break
            fi
        done

        if [ "$match" == "true" ] && [ -d "$dir" ]; then
            builtin cd "$dir"
            return
        fi
    done
    
    return 1
}
