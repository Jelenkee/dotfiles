zz(){
    # subcommands
    if [ "$1" == "--" ]; then
        if [ "$2" == "list" ]; then
            cat $DF_CD_CACHE_FILE | sort -nr
        elif [ "$2" == "clear" ]; then
            rm $DF_CD_CACHE_FILE
            touch $DF_CD_CACHE_FILE
        elif [ "$2" == "remove" ]; then
            local dir="$3"
            if [ "$dir" == "" ]; then
                dir="$PWD"
            fi
            local line_number=$(grep -F -n "	$dir	" "$DF_CD_CACHE_FILE" | cut -f1 -d:)
            if [ ! "$line_number" == "" ]; then
                sed -i "${line_number}d" $DF_CD_CACHE_FILE
            fi
        elif [ "$2" == "add" ]; then
            if [ ! "$HOME" == "$PWD" ] && [ ! "$OLDPWD" == "$PWD" ] && [[ ! "$PWD" == *$'\n'* ]]; then
                touch "$DF_CD_CACHE_FILE"
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
            fi
        fi
        return
    fi
    
    # default
    if builtin cd $@ 2> /dev/null; then
        return
    fi

    local dry=false

    if [ "$1" == "-q" ]; then 
        dry=true
        shift
    fi
    
    local args=("$@")
    local _arr2
    local dia

    readarray -t _arr2 < <(cat $DF_CD_CACHE_FILE | sort -nr | awk -F '\t' '{print $2}')
    dia=$(_df_search_dir _arr2[@] args[@])
    if [ ! "$dia" == "" ]; then
        if [ "$dry" == "true" ]; then
            echo "$dia"
        else
            builtin cd "$dia"
        fi
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
    
    local _arr1
    local _arr2
    local dia
    
    readarray -t -d '' _arr1 < <(find . -mindepth $len -maxdepth $len -type d -iname "*${last_arg}*" -print0)
    dia=$(_df_search_dir _arr1[@] args[@])
    if [ ! "$dia" == "" ]; then
        builtin cd "$dia"
        return
    fi
    
    readarray -t -d '' _arr2 < <(find . -mindepth $plus_len -maxdepth $plus_len -type d -iname "*${last_arg}*" -print0)
    dia=$(_df_search_dir _arr2[@] args[@])
    if [ ! "$dia" == "" ]; then
        builtin cd "$dia"
        return
    fi
    
    return 1
}

_df_search_dir() {
    local dirs=("${!1}")
    local terms=("${!2}")
    
    local modes=("sw" "sw." "con")
    
    for mode in "${modes[@]}"; do
        for dir in "${dirs[@]}"; do
            local match=true
            local last_term="${terms[-1]}"
            local base="$(basename "$dir")"
            
            case $mode in
                "sw")
                    local index=$(echo "$base" | grep -F -i -b -o "$last_term" | head -n 1 | cut -d':' -f1)
                    if [ ! "$index" == "0" ]; then
                        continue
                    fi
                ;;
                "sw.")
                    local index=$(echo "$base" | grep -F -i -b -o "$last_term" | head -n 1 | cut -d':' -f1)
                    local first="${base:0:1}"
                    if [ ! "$index" == "1" ] || [ ! "$first" == "." ]; then
                        continue
                    fi
                ;;
                "con")
                    if ! echo "$base" | grep -F -q -i "$last_term"; then
                        continue
                    fi
                ;;
            esac
            
            local len=${#terms[@]}
            local pre_terms=("${terms[@]:0:$((len - 1))}")
            
            for term in "${pre_terms[@]}"; do
                if ! echo "$dir" | grep -F -q -i "$term"; then
                    match=false
                    break
                fi
            done
            
            if [ "$match" == "true" ] && [ -d "$dir" ]; then
                echo "$dir"
                return
            fi
        done
    done
    
    return 1
}
