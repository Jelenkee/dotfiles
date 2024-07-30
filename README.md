## dotfiles (bash)

You need to have [stow](https://www.gnu.org/software/stow/) installed!

## Setup

* clone this repo to `~/dotfiles`
* cd into the repo and run `stow .`
* run `echo -e "\nsource ~/.scripts/iniit.sh" >> ~/.bashrc`
* open a new terminal or run `source ~/.bashrc`
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
* `upload` - upload small files for a day
* `mkd` - create dir and cd into it
* `edit` - edit file
* `ebrc` - edit ~/.bashrc
* `serve` - start http file server in current directory
* `pwgen` - generates password
* `search` - search files (recursively)
* `searchd` - search directories (recursively)
* `killport` - kills process for given port
* `erase` - removes cache, trash and more stuff that uses disk space

## Env
* `DF_POOR_PROMPT=1` to disable special glyphs
* `DF_PROMPT_ID=XX` to display a custom id
