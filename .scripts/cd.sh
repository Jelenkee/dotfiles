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
            if [ ! "$HOME" == "$PWD" ] && [ ! "$OLDPWD2" == "$PWD" ] && [[ ! "$PWD" == *$'\n'* ]]; then
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

    local dia=$(_df_zz $@)
    if [ ! "$dia" == "" ]; then
        builtin cd "$dia"
        return
    fi

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
    
    readarray -t -d '' _arr1 < <(find -L . -mindepth $len -maxdepth $len -type d -iname "*${last_arg}*" -print0)
    dia=$(_df_search_dir _arr1[@] args[@])
    if [ ! "$dia" == "" ]; then
        builtin cd "$dia"
        return
    fi
    
    readarray -t -d '' _arr2 < <(find -L . -mindepth $plus_len -maxdepth $plus_len -type d -iname "*${last_arg}*" -print0)
    dia=$(_df_search_dir _arr2[@] args[@])
    if [ ! "$dia" == "" ]; then
        builtin cd "$dia"
        return
    fi
    
    return 1
}

