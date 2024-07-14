export PROMPT_COMMAND=set_prompt
_AT_PROMPT=1
_FIRST_PROMPT=1
#DF_START_DATE=$(date +%s)
set_prompt() {
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
    export PS1="\[\e[1;36m\]$s1\[\e[1;32m\]$id\[\e[1;32m\]\w"
    # git
    PS1+="\[\e[0;37m\]$(_git_info)"
    # result
    PS1+="$(_last_result $_status)$(_execution_time $diff)"
    # prompt
    PS1+="\[\e[1;36m\]\n$s2$bracket "
    # reset
    PS1+="\[\e[m\]"
    export PS2="\[\e[36m\]> "
    
    local current_dir=$(pwd)
    touch "$DF_CD_CACHE_FILE"
    if ! grep -F -q -x "$current_dir" "$DF_CD_CACHE_FILE";then
        echo "$current_dir" >> $DF_CD_CACHE_FILE
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
    if [ ! "${BRANCH}" == "" ]
    then
        STAT=$(_git_status)
        echo " ${BRANCH}${STAT}"
    else
        echo ""
    fi
}

# get current status of git repo
_git_status() {
    local staged=$(git diff --name-only --cached)
    local changes=$(git diff --name-only)
    local untracked=$(git status --porcelain | grep '^??')
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
function PreCommand() {
    if [ -z "$_AT_PROMPT" ]; then
        return
    fi
    unset _AT_PROMPT
    
    DF_START_DATE=$(date +%s)
}
trap "PreCommand" DEBUG
