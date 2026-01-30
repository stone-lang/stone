SHELL := env PATH=$(PATH) /bin/bash
BUNDLE_CHECK := $(shell bundle check >/dev/null ; echo $$?)
LLVM_PREFIX := $(shell brew --prefix llvm 2>/dev/null || mise where llvm 2>/dev/null || echo)
PATH := $(LLVM_PREFIX)/bin:$(PATH)
DYLD_LIBRARY_PATH := $(LLVM_PREFIX)/lib:$(DYLD_LIBRARY_PATH)
LD_LIBRARY_PATH := $(LLVM_PREFIX)/lib:$(LD_LIBRARY_PATH)
LDFLAGS := "-L$(LLVM_PREFIX)/lib"
CPPFLAGS := "-I$(LLVM_PREFIX)/include"
RUBYOPT := --enable=frozen-string-literal
export PATH
export DYLD_LIBRARY_PATH
export LD_LIBRARY_PATH
export RUBYOPT

all: setup deps test lint

ci: specs lint

setup: bun node_modules/.bin/markdownlint-cli2 llvm bundle_config

bundle_config:
ifndef CI
	@mise exec -- bundle config local.grammy ~/Work/Code/grammy
endif

deps: bundle

test: specs

specs: rspec

console: bundle
	@mise exec -- bundle exec pry -I lib -r stone -r grammy

lint: rubocop markdownlint

rspec: bundle
	DEBUG=0 mise exec -- bundle exec rspec $(FILE)

bundle:
ifneq ($(BUNDLE_CHECK), 0)
	@echo $(PATH)
	@mise exec -- bundle install
endif

Gemfile.lock: Gemfile
	@mise exec -- bundle

rubocop:
	@mise exec -- bundle exec rubocop $(or $(FILE), lib spec)

markdownlint: node_modules/.bin/markdownlint-cli2
	@mise exec -- bunx markdownlint-cli2 '**/*.md' '!vendor' '!node_modules'

node_modules/.bin/markdownlint-cli2:
	@mise exec -- bun install markdownlint-cli2

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

.PHONY: all ci setup deps test specs console lint rspec bundle bundle_config rubocop markdownlint bun llvm
