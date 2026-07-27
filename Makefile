ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
PATH := ~/.local/bin:$(PATH)

all: restow

restow:
	@cd ${ROOT_DIR}
	@find ${ROOT_DIR}/.local/bin -type f -exec chmod +x {} \;
	stow --target $(HOME) --verbose --restow --no-folding --ignore='Makefile' .
	
delete:
	cd ${ROOT_DIR}
	stow --target $(HOME) --verbose --delete .

apply:
	@cd ${MAKEFILE_DIR}
	@if ! type mise > /dev/null 2>&1; then curl https://mise.run | sh; mise doctor; fi
	@mise trust
	@mise dotfiles apply -y
	@echo $(MAKEFILE_DIR)
	@echo $(PATH)

.PHONY: all restow delete apply