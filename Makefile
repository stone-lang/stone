SHELL := env PATH=$(PATH) /bin/bash
BUNDLE_CHECK := $(shell bundle check >/dev/null ; echo $$?)
LLVM_PREFIX := $(shell brew --prefix llvm 2>/dev/null || echo "/usr/local/opt/llvm")
PATH := $(LLVM_PREFIX)/bin:$(PATH)
DYLD_LIBRARY_PATH := $(LLVM_PREFIX)/lib:$(DYLD_LIBRARY_PATH)
LDFLAGS := "-L$(LLVM_PREFIX)/lib"
CPPFLAGS := "-I$(LLVM_PREFIX)/include"
export PATH
export DYLD_LIBRARY_PATH

all: setup test lint

setup: bun node_modules/.bin/markdownlint-cli2 llvm

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
	@bundle
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
	@brew install llvm

.PHONY: all setup test specs console lint rspec bundle rubocop markdownlint bun llvm
