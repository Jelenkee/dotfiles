ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
KEY:=qpqBVwsQg2fe3YOA

all: restow

restow:
	@cd ${ROOT_DIR}
	@find ${ROOT_DIR}/.local/bin -type f -exec chmod +x {} \;
	stow --target $(HOME) --verbose --restow --no-folding --ignore='Makefile' .
	@sed -i '/${KEY}/d' ~/.bashrc
	@sed -i ':a;/^\n*$$/{$$d;N;ba}' ~/.bashrc
	@printf "\nsource ~/.scripts/iniit.sh ##${KEY}\n" >> ~/.bashrc
	

delete:
	cd ${ROOT_DIR}
	stow --verbose --delete .

.PHONY: all restow delete