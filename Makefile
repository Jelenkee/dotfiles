ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

all: restow

restow:
	@cd ${ROOT_DIR}
	@find ${ROOT_DIR}/.local/bin -type f -exec chmod +x {} \;
	stow --target $(HOME) --verbose --restow --no-folding --ignore='Makefile' .
	

delete:
	cd ${ROOT_DIR}
	stow --target $(HOME) --verbose --delete .

.PHONY: all restow delete