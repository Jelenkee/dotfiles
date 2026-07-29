ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
PATH := ~/.local/bin:$(PATH)

all: restow

restow:
	@find ${ROOT_DIR}/.local/bin -type f -exec chmod +x {} \;
	stow --target $(HOME) --verbose --restow --no-folding ${ROOT_DIR}
	
delete:
	stow --target $(HOME) --verbose --delete ${ROOT_DIR}

apply: mise
	@find ${MAKEFILE_DIR}/.local/bin -type f -exec chmod +x {} \;
	mise bootstrap dotfiles apply -yv

unapply: mise
	mise bootstrap dotfiles unapply -yv

mise:
	@if ! type mise > /dev/null 2>&1; then curl https://mise.run | sh; mise doctor; fi
	@mise trust -y -q -C ${MAKEFILE_DIR}

.PHONY: all restow delete apply unapply mise