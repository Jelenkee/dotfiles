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

