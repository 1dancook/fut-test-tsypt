# Path to the TOML file
TOML_FILE = typst.toml

# Extract values from the TOML file using grep and sed
NAME := $(shell grep '^name =' $(TOML_FILE) | sed 's/name = "\(.*\)"/\1/')
VERSION := $(shell grep '^version =' $(TOML_FILE) | sed 's/version = "\(.*\)"/\1/')

# Destination path
DEST_DIR := $(HOME)/Library/Application Support/typst/packages/local/$(NAME)/$(VERSION)

# Package DIR
PACKAGE_DIR := $(HOME)/Library/Application Support/typst/packages/local/$(NAME)

# Default target
all: install

install:
	@echo "Installing $(NAME) version $(VERSION)"
	mkdir -p "$(DEST_DIR)"
	rsync -av --exclude='.git' --exclude='makefile' ./ "$(DEST_DIR)/"

uninstall:
	@echo "Uninstalling $(NAME) version $(VERSION)"
	rm -rf "$(DEST_DIR)"

preview:
	typst compile --root . template/main.typ --open

preview-ak:
	typst compile --root . --open --input answerkey=true template/main.typ

.PHONY: all install uninstall
