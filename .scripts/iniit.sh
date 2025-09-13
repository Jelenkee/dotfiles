SCRIPT_DIR=$(builtin cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

for f in $(ls -1 $SCRIPT_DIR | grep -Fv "iniit.sh"); do
    source "$SCRIPT_DIR/$f"
done

unset f
unset SCRIPT_DIR

DF_DATA_DIR="$HOME/.local/share/_dotfiles"
mkdir -p -v "$DF_DATA_DIR"
export DF_CD_CACHE_FILE="${DF_DATA_DIR}/cd_history.txt"
touch "$DF_CD_CACHE_FILE"

if [ "$DF_PROMPT_ID" == "" ]; then
    echo "Set DF_PROMPT_ID"
fi

if [ ! "$(type -t nano)" == "" ]; then
    vers=$(nano --version | _parse_version)
    major=$(echo $vers | grep --color=never -o -P "\\d+" | head -n1)
    if ((major < 8)); then
        echo "Upgrade to nano 8"
    fi
fi

if [ ! "$(type -t git)" == "" ]; then
    vers=$(git --version | _parse_version)
    major=$(echo $vers | grep --color=never -o -P "\\d+" | head -n1)
    minor=$(echo $vers | grep --color=never -o -P "\\d+" | tail +2 | head -n1)
    if ((major < 2)); then
        echo "Upgrade to git 2"
    fi
    if ((minor < 37)); then
        echo "Upgrade to git 2.37"
    fi
fi

if [ ! "$(type -t bash)" == "" ]; then
    vers=$(bash --version | _parse_version)
    major=$(echo $vers | grep --color=never -o -P "\\d+" | head -n1)
    if ((major < 5)); then
        echo "Upgrade to bash 5"
    fi
fi
