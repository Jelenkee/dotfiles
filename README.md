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
* Aliases and functions
    * see below

## Aliases/Functions

* `up` - updates all packages
* `deps` - installs an opionated list of tools
* `z`/`zz` - smart search (similar to zoxide)
    * `z -- list` - list history
    * `z -- clear` - clear history
* `erase` - removes cache, trash and more stuff that uses disk space
* `upload` - upload small files for a day

## Env
* `DF_POOR_PROMPT=1` to disable special glyphs
* `DF_PROMPT_ID=XX` to display a custom id
* `DF_Z_HOME_DEPTH=5` max depth to search for folders (0 to disable)
