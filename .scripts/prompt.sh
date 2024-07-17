export PROMPT_COMMAND=_set_prompt
_AT_PROMPT=1
_FIRST_PROMPT=1

_set_prompt() {
    local _status="$?"
    local id="${DF_PROMPT_ID}"
    if [ ! "$id" == "" ]; then
        id+=" "
    fi
    local bracket=$(_is_poor_prompt && echo ">" || echo "❯")
    local s1=$(_is_poor_prompt && echo "" || echo "╭")
    local s2=$(_is_poor_prompt && echo "" || echo "╰")
    local hourglass=$(_is_poor_prompt && echo "" || echo "⧗")
    #local fancy = "\ue0b6 \ue0b4 • ●"
    
    local now_date=$(date +%s)
    local diff=$(($now_date-$DF_START_DATE))
    local time=$(_execution_time $diff)
    export PS1="\[\e[1;36m\]$s1\[\e[1;32m\]$id\[\e[1;32m\]\w"
    # git
    PS1+="\[\e[0;37m\]$(_git_info)"
    # result
    PS1+="$(_last_result $_status)$time"
    # prompt
    PS1+="\[\e[1;36m\]\n$s2$bracket "
    # reset
    PS1+="\[\e[m\]"
    export PS2="\[\e[36m\]> "
    
    touch "$DF_CD_CACHE_FILE"
    if [ ! "$HOME" == "$PWD" ] && [ ! "$last_dir" == "$PWD" ];then
        local line_number=$(grep -F -n "	$PWD	" "$DF_CD_CACHE_FILE" | cut -f1 -d:)
        if [ ! "$line_number" == "" ];then
            local line=$(head -n $line_number "$DF_CD_CACHE_FILE" | tail -n 1)
            local count=$(echo $line | awk '{print $1}')
            local count=$(($count+1))
            sed -i "${line_number}d" $DF_CD_CACHE_FILE
            echo -e "$count\t$PWD\t" >> $DF_CD_CACHE_FILE
        else
            echo -e "1\t$PWD\t" >> $DF_CD_CACHE_FILE
        fi
    fi
    
    _AT_PROMPT=1
    if [ -n "$_FIRST_PROMPT" ]; then
        unset _FIRST_PROMPT
        return
    fi
}

# get current branch in git repo
_git_info() {
    local BRANCH=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
    if [ ! "${BRANCH}" == "" ];then
        local STAT="$(_git_status2)"
        echo " ${BRANCH}${STAT}"
    else
        echo ""
    fi
}


# get current status of git repo
_git_status2() {
    local status=$(git status --porcelain)
    local staged=$(echo "$status" | grep '^M')
    local changes=$(echo "$status" | grep '^ M')
    local untracked=$(echo "$status" | grep '^??')
    local bits=""
    if [ ! "$staged" == "" ]; then
        bits+="+"
    fi
    if [ ! "$changes" == "" ] || [ ! "$untracked" == "" ]; then
        bits+="*"
    fi
    
    if [ ! "$bits" == "" ]; then
        echo -n " $bits"
    else
        echo -n ""
    fi
}

_last_result() {
    if [ "$1" == "0" ]; then
        echo -n " \[\e[0;32m\]✔"
    else
        echo -n " \[\e[0;31m\]✘($1)"
    fi
}

_execution_time() {
    if [ "$1" -ge 5 ]; then
        echo -n " \[\e[m\]${1}s"
    else
        echo -n ""
    fi
}

_is_poor_prompt() {
    [ "$DF_POOR_PROMPT" == "1" ]
}

# This will run before any command is executed.
function _PreCommand() {
    if [ -z "$_AT_PROMPT" ]; then
        return
    fi
    unset _AT_PROMPT
    
    DF_START_DATE=$(date +%s)
    last_dir="$PWD"
}
trap "_PreCommand" DEBUG
