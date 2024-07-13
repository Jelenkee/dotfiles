export PROMPT_COMMAND=set_prompt
set_prompt() {
    local _status="$?"
	local lambda=$([ "$POOR_PROMPT" == "1" ] && echo "" || echo "λ ")
	local bracket=$([ "$POOR_PROMPT" == "1" ] && echo ">" || echo "❯")
	local s1=$([ "$POOR_PROMPT" == "1" ] && echo "" || echo "╭")
	local s2=$([ "$POOR_PROMPT" == "1" ] && echo "" || echo "╰")

    export PS1="\[\e[1;36m\]$s1\[\e[1;32m\]$lambda\[\e[1;32m\]\w"
	# git
	PS1+="\[\e[0;37m\]$(_git_info)"
	# result
	#PS1+="$(_last_result $_status)"
	# prompt
	PS1+="\[\e[1;36m\]\n$s2$bracket "
	# reset
    PS1+="\[\e[m\]"
    export PS2="\[\e[36m\]> "
}

# get current branch in git repo
function _git_info() {
    BRANCH=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
    if [ ! "${BRANCH}" == "" ]
    then
        STAT=$(_git_status)
        echo " ${BRANCH}${STAT}"
    else
        echo ""
    fi
}

# get current status of git repo
function _git_status {
    staged=$(git diff --name-only --cached)
    changes=$(git diff --name-only)
    untracked=$(git status --porcelain | grep '^??')
    bits=""
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

function _last_result {
    if [ "$0" == "0" ]; then
        echo -n " ✔"
    else
        echo -n " ✘"
    fi
}

