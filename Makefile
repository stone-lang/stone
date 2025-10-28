SHELL := env PATH=$(PATH) /bin/bash
BUNDLE_CHECK := $(shell bundle check >/dev/null ; echo $$?)
LLVM_PREFIX := $(shell brew --prefix llvm 2>/dev/null || { [ -d /usr/lib/llvm-21 ] && echo /usr/lib/llvm-21; } || mise where llvm 2>/dev/null || echo)
PATH := $(LLVM_PREFIX)/bin:$(PATH)
DYLD_LIBRARY_PATH := $(LLVM_PREFIX)/lib:$(DYLD_LIBRARY_PATH)
LDFLAGS := "-L$(LLVM_PREFIX)/lib"
CPPFLAGS := "-I$(LLVM_PREFIX)/include"
export PATH
export DYLD_LIBRARY_PATH

all: setup deps test lint

setup: bun node_modules/.bin/markdownlint-cli2 llvm

deps: bundle

test: specs

specs: rspec

console: bundle
	@bundle exec pry -I lib -r stone -r grammy

lint: markdownlint rubocop

rspec: bundle
	DYLD_LIBRARY_PATH="$(LLVM_PREFIX)/lib:$(DYLD_LIBRARY_PATH)" DEBUG=0 bundle exec rspec

bundle:
ifneq ($(BUNDLE_CHECK), 0)
	@echo $(PATH)
	@bundle install
endif

Gemfile.lock: Gemfile
	@bundle

rubocop:
	bundle exec rubocop .

markdownlint: node_modules/.bin/markdownlint-cli2
	@bunx markdownlint-cli2 '**/*.md' '!vendor' '!node_modules'

node_modules/.bin/markdownlint-cli2:
	@bun install markdownlint-cli2

bun:
	@which bun >/dev/null || mise install bun || curl -fsSL https://bun.sh/install | bash

llvm:
	@LLVM_VERSION=$$(grep '^llvm ' .tool-versions | awk '{print $$2}'); \
	if command -v brew >/dev/null 2>&1; then \
		echo "Installing LLVM $$LLVM_VERSION via Homebrew..."; \
		brew install llvm@$$LLVM_VERSION 2>/dev/null || brew install llvm; \
	elif command -v apt-get >/dev/null 2>&1; then \
		echo "Installing LLVM $$LLVM_VERSION via apt-get..."; \
		sudo apt-get update && sudo apt-get install -y llvm-$$LLVM_VERSION-dev llvm-$$LLVM_VERSION 2>/dev/null || \
		sudo apt-get install -y llvm-dev llvm; \
	else \
		echo "No package manager found. Installing via mise..."; \
		mise plugin ls | grep -q '^llvm$$' || mise plugin add llvm https://github.com/higebu/asdf-llvm.git; \
		mise install llvm; \
	fi

.PHONY: all setup deps test specs console lint rspec bundle rubocop markdownlint bun llvm
