DOT_DIR=$(builtin cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
KEY="qpqBVwsQg2fe3YOA"

cd $DOT_DIR
git pull
stow . -R --no-folding
if ! grep -q "$KEY" ~/.bashrc; then
    echo -e "\nsource ~/.scripts/iniit.sh ##$KEY" >> ~/.bashrc
fi