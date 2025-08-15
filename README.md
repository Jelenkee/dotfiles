## dotfiles (bash)

You need to have [stow](https://www.gnu.org/software/stow/) installed!

## Setup

* Clone this repo
* cd into the repo and run `make`
* Open a new terminal or run `source ~/.bashrc`

## Features

* Custom prompt
    * git status
    * last result
    * execution time
* Aliases and functions
    * see below

## Aliases/Functions

* `up` - updates (nearly) everything
* `z`/`zz` - smart navigation (similar to zoxide)
    * `z -- list` - list history
    * `z -- clear` - clear history
* `cd` - smarter cd
* `upload` - upload small files for 24 hours
* `mkd` - create dir and cd into it
* `edit` - edit file
* `ebrc` - edit ~/.bashrc
* `sbrc` - source ~/.bashrc
* `serve` - starts http file server in current directory
* `pwgen` - generates password
* `ffetch` - shows basic system information
* `search` - searches files (recursively)
* `searchd` - searches directories (recursively)
* `killport` - kills process for given port
* `erase` - removes cache, trash and more stuff that uses disk space
* `ports` - lists open ports
* `paths` - lists dirs with executables ($PATH)
* `eecho` - echo for stderr

## Env
* `DF_POOR_PROMPT=1` to disable special glyphs
* `DF_PROMPT_ID=XX` to display a custom id
