#SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
#cd $SCRIPT_DIR;

#stow $SCRIPT_DIR
stow .

# TODO add dependencies to bashrc (check if exists)

init_line=$(grep -F "iniit.sh"  ~/.bashrc)
echo $init_line
[ "$init_line" == "" ] && echo -e "\nsource ~/.scripts/iniit.sh" >> ~/.bashrc
unset init_line
