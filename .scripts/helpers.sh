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