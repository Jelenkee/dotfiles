ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
PATH := ~/.local/bin:$(PATH)

all: apply

restow:
	@find ${ROOT_DIR}/.local/bin -type f -exec chmod +x {} \;
	cd ${ROOT_DIR} && stow --target $(HOME) --verbose --restow --no-folding .
	
delete:
	cd ${ROOT_DIR} && stow --target $(HOME) --verbose --delete .

apply: mise
	@find ${MAKEFILE_DIR}/.local/bin -type f -exec chmod +x {} \;
	mise bootstrap dotfiles apply -yv
	mkdir -p ~/.config/mise
	touch ~/.config/mise/config.local.toml
	cd && mise bootstrap -y

unapply: mise
	mise bootstrap dotfiles unapply -yv

mise:
	@if ! type mise > /dev/null 2>&1; then \
		make delete; \
		curl https://mise.run | sh; \
		if mise version 2>&1 | grep -iq glibc; then \
			export MISE_INSTALL_MUSL=1 \
			curl https://mise.run | sh; \
		fi; \
		mise doctor || true; \
	fi
	@mise trust -y -q -C ${MAKEFILE_DIR}

.PHONY: all restow delete apply unapply mise