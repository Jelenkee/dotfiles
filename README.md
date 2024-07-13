## dotfiles (bash)

You need to have [stow](https://www.gnu.org/software/stow/) installed!

## Setup

* clone this repo to `~/dotfiles`
* cd into the repo and run `stow .`
* open a new terminal or run `echo -e "\nsource ~/.scripts/iniit.sh" >> ~/.bashrc`
* run `source ~/.bashrc`

* ...
* profit

## Features

* Custom prompt
    * git status
    * last result
    * execution time
* ...


## Env
* `DF_POOR_PROMPT=1` to disable special glyphs
* `DF_PROMPT_ID=XX` to display a custom id
