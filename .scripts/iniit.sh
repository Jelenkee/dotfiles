SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

for f in $(ls -1 $SCRIPT_DIR | grep -Fv "iniit.sh"); do
    source "$SCRIPT_DIR/$f"
done

unset SCRIPT_DIR
