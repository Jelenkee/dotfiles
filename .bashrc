 # If not running interactively, don't do anything
[[ $- != *i* ]] && return

if [ -f ~/.startup.sh ]; then
    . ~/.startup.sh
fi

# source scripts
for f in ~/.scripts/*; do
    . "$f"
done
unset f

# create files for zz
DF_DATA_DIR="$HOME/.local/share/_dotfiles"
mkdir -p -v "$DF_DATA_DIR"
export DF_CD_CACHE_FILE="${DF_DATA_DIR}/cdhistory.txt"
touch "$DF_CD_CACHE_FILE"

# warnings
if [ "$DF_PROMPT_ID" == "" ]; then
    eecho "Set DF_PROMPT_ID"
fi

if [ ! "$(type -t nano)" == "" ]; then
    vers=$(nano --version | _parse_version)
    major=$(echo $vers | grep --color=never -o -P "\\d+" | head -n1)
    if ((major < 8)); then
        eecho "Upgrade to nano 8"
    fi
fi

if [ ! "$(type -t git)" == "" ]; then
    vers=$(git --version | _parse_version)
    major=$(echo $vers | grep --color=never -o -P "\\d+" | head -n1)
    minor=$(echo $vers | grep --color=never -o -P "\\d+" | tail -n +2 | head -n1)
    if ((major < 2)); then
        eecho "Upgrade to git 2"
    fi
    if ((minor < 37)); then
        eecho "Upgrade to git 2.37"
    fi
fi

if [ ! "$(type -t bash)" == "" ]; then
    vers=$(bash --version | _parse_version)
    major=$(echo $vers | grep --color=never -o -P "\\d+" | head -n1)
    if ((major < 5)); then
        eecho "Upgrade to bash 5"
    fi
fi

# completion
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi


if [ -f ~/.localbashrc ]; then
    . ~/.localbashrc
fi

#### ⚠️ DONT CUSTOMIZE HERE! USE .localbashrc INSTEAD ⚠️ ####