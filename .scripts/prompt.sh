bold=$(tput bold)
normal=$(tput sgr0)

export PROMPT_COMMAND=set_prompt
set_prompt() {
    _status="$?"
    export PS1="\[\e[1;32m\]@\u \w"
	# git
	PS1+="\[\e[0;37m\]\$(_git_info)"
	# result
	#PS1+="$(_last_result $_status)"
	# prompt
	PS1+="\[\e[1;36m\]\n❯"
	# reset
    PS1+=" \[\e[m\]"
    export PS2="\[\e[36m\]> "
}

# get current branch in git repo
function _git_info() {
    BRANCH=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
    if [ ! "${BRANCH}" == "" ]
    then
        STAT=`_git_status`
        echo " ${BRANCH}${STAT}"
    else
        echo ""
    fi
}

# get current status of git repo
function _git_status {
    status=$(git status 2>&1 | tee)
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
        echo -n " ✓"
    else
        echo -n " ✖"
    fi
}

