ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
KEY:=qpqBVwsQg2fe3YOA

all: restow

restow:
	cd ${ROOT_DIR}
	find ${ROOT_DIR}/.local/bin -type f -exec chmod +x {} \;
	stow --target $(HOME) --verbose --restow --no-folding --ignore='Makefile' .
	@if ! grep -q "${KEY}" ~/.bashrc; then echo -e "\nsource ~/.scripts/iniit.sh ##${KEY}" >> ~/.bashrc; fi
	

delete:
	cd ${ROOT_DIR}
	stow --verbose --delete .

.PHONY: all restow delete