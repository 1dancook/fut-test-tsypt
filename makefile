# Path to the TOML file
TOML_FILE = typst.toml

# Extract values from the TOML file using grep and sed
NAME := $(shell grep '^name =' $(TOML_FILE) | sed 's/name = "\(.*\)"/\1/')
NAMESPACE := $(shell grep '^namespace =' $(TOML_FILE) | sed 's/namespace = "\(.*\)"/\1/')
VERSION := $(shell grep '^version =' $(TOML_FILE) | sed 's/version = "\(.*\)"/\1/')

# Destination path
DEST_DIR := $(HOME)/Library/Application Support/typst/packages/$(NAMESPACE)/$(NAME)/$(VERSION)

# Package DIR
PACKAGE_DIR := $(HOME)/Library/Application Support/typst/packages/$(NAMESPACE)/$(NAME)

# Default target
all: install

install:
	@echo "Installing $(NAME) version $(VERSION) in namespace $(NAMESPACE)"
	mkdir -p "$(DEST_DIR)"
	rsync -av --exclude='.git' --exclude='makefile' ./ "$(DEST_DIR)/"

uninstall:
	@echo "Uninstalling $(NAME) version $(VERSION) from namespace $(NAMESPACE)"
	rm -rf "$(DEST_DIR)"


.PHONY: all install uninstall
