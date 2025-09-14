zz(){
    local array=();
    while IFS= read -r -d '' part; do
        array+=("$part")
    done < $DF_CD_CACHE_FILE;
    local arraylength=${#array[@]}
    local indices=();
    for (( i=0; i<${arraylength}; i+=2 ));
    do
        indices+=("$i")
    done
    local length=${#indices[@]}
    for ((i = 0; i < length; i++)); do
        for ((j = 0; j < length-i-1; j++)); do
            if (( ${array[${indices[j]}]} <= ${array[${indices[j + 1]}]} )); then
                temp=${indices[j]}
                indices[j]=${indices[j + 1]}
                indices[j + 1]=$temp
            fi
        done
    done
    local sarray=();
    for ((i = 0; i < length; i++)); do
        local index=${indices[i]}
        sarray+=(${array[$index]})
        sarray+=(${array[$((index+1))]})
    done
    local dirarray=();
    for (( i=1; i<${arraylength}; i+=2 ));
    do
        dirarray+=("${sarray[i]}")
    done

    if [ "$1" == "-l" ]; then
        for (( i=0; i<${arraylength}; i+=2 ));
        do
            echo -e "${sarray[$((i+1))]}: ${sarray[$i]}"
        done
        return
    elif [ "$1" == "-c" ]; then
        rm $DF_CD_CACHE_FILE
        touch $DF_CD_CACHE_FILE
        return
    elif [ "$1" == "-r" ]; then
        true # TODO
        return
    elif [ "$1" == "-1" ]; then
        local args=("$2")
        local dia=$(_df_search_dir dirarray[@] args[@])
        echo -n "$dia"
        return
    elif [ "$1" == "-a" ]; then
        if [ "$HOME" == "$PWD" ]; then
            return
        fi
        touch $DF_CD_CACHE_FILE
        local countIndex="";
        for (( i=1; i<${arraylength}; i+=2 ));
        do
            if [ "$PWD" == "${array[$i]}" ];then
                countIndex=$((i-1));
                break;
            fi
        done
        if [ ! "$countIndex" == "" ]; then
            array[$countIndex]=$((array[$countIndex] + 1))
        else
            array+=("1")
            array+=("$PWD")
        fi
        printf "%s\0" "${array[@]}" > $DF_CD_CACHE_FILE
        return
    fi
    
    # default
    if builtin cd "$@" 2> /dev/null; then
        zz -a
        return
    fi

    local args=("$1")
    local dia=$(_df_search_dir dirarray[@] args[@])
    if [ ! "$dia" == "" ]; then
        builtin cd "$dia" && zz -a
        return
    fi

    return 1
}

cd() {
    # default
    if builtin cd "$@" 2> /dev/null; then
        zz -a
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
        builtin cd "$dia" && zz -a
        return
    fi
    
    readarray -t -d '' _arr2 < <(find -L . -mindepth $plus_len -maxdepth $plus_len -type d -iname "*${last_arg}*" -print0)
    dia=$(_df_search_dir _arr2[@] args[@])
    if [ ! "$dia" == "" ]; then
        builtin cd "$dia" && zz -a
        return
    fi
    
    return 1
}

_df_search_dir() {
    local dirs=("${!1}")
    local terms=("${!2}")
    local last_term="${terms[-1]}"
    last_term="${last_term,,}"
    
    local modes=("sw" "sw." "con")
    
    for mode in "${modes[@]}"; do
        for dir in "${dirs[@]}"; do
            local match=true
            local base="$(_df_basename "$dir")"
            base="${base,,}"
            
            case $mode in
                "sw")
                    if [[ ! "$base" == "$last_term"* ]]; then
                        continue
                    fi
                ;;
                "sw.")
                    if [[ ! "$base" == ".$last_term"* ]]; then
                        continue
                    fi
                ;;
                "con")
                    if [[ ! "$base" == *"$last_term"* ]]; then
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

_df_basename() {
    local path="$1"
    if [ "$path" == "/" ]; then
        echo "/"
        return
    fi
    local slash="/"
    path="${path%/}"
    echo "${path##*$slash}"
}