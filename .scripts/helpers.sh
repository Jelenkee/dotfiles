_df_search_dir() {
    local dirs=("${!1}")
    local terms=("${!2}")
    local last_term="${terms[-1]}"
    last_term="${last_term,,}"
    
    local modes=("sw" "sw." "con")
    
    for mode in "${modes[@]}"; do
        for dir in "${dirs[@]}"; do
            local match=true
            local base="$(basename "$dir")"
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