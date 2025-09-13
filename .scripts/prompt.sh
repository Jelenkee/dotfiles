export PROMPT_COMMAND=_df_set_prompt
_AT_PROMPT=1
_FIRST_PROMPT=1

_df_set_prompt() {
    local _status="$?"
    local id="${DF_PROMPT_ID}"
    if [ ! "$id" == "" ]; then
        id+=" "
    fi
    local bracket=$(_df_is_poor_prompt && echo ">" || echo "❯")
    local s1=$(_df_is_poor_prompt && echo "" || echo "╭")
    local s2=$(_df_is_poor_prompt && echo "" || echo "╰")
    #local fancy = "\ue0b6 \ue0b4 • ●"
    
    local now_date=$(date +%s)
    local diff=$(($now_date - $DF_START_DATE))
    local time=$(_df_execution_time $diff)
    export PS1="\[\e[1;36m\]$s1\[\e[1;32m\]$id\[\e[1;32m\]\w"
    # git
    PS1+="\[\e[0;37m\]$(_df_git_info)"
    # result
    PS1+="$(_df_last_result $_status)$time"
    # prompt
    PS1+="\n\[\e[1;36m\]$s2$bracket "
    # reset
    PS1+="\[\e[m\]"
    export PS2="\[\e[36m\]>\[\e[m\] "
    
    zz -- add
    
    _AT_PROMPT=1
    if [ -n "$_FIRST_PROMPT" ]; then
        unset _FIRST_PROMPT
        return
    fi
}

# get current branch in git repo
_df_git_info() {
    local BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ ! "${BRANCH}" == "" ]; then
        local STAT="$(_df_git_status)"
        echo " ${BRANCH}${STAT}"
    else
        echo ""
    fi
}

# get current status of git repo
_df_git_status() {
    local status=$(git status --porcelain)
    local staged=$(echo "$status" | grep '^[A-Z] ')
    local changes=$(echo "$status" | grep '^ [A-Z]')
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

_df_last_result() {
    if [ "$1" == "0" ]; then
        echo -n " \[\e[0;32m\]✔"
    else
        echo -n " \[\e[0;31m\]✘($1)"
    fi
}

_df_execution_time() {
    if [ "$1" -ge 5 ]; then
        echo -n " \[\e[m\]${1}s"
    else
        echo -n ""
    fi
}

_df_is_poor_prompt() {
    [ "$DF_POOR_PROMPT" == "1" ]
}

# This will run before any command is executed.
function _PreCommand() {
    if [ -z "$_AT_PROMPT" ]; then
        return
    fi
    unset _AT_PROMPT
    export OLDPWD2="$PWD"
    
    DF_START_DATE=$(date +%s)
}
trap "_PreCommand" DEBUG
