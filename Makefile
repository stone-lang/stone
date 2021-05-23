SHELL := /bin/bash
BUNDLE_CHECK := $(shell bundle check >/dev/null ; echo $$?)

all: setup verify-specs rspec

setup: setup-overcommit

console:
	bundle exec pry -I src -r stone/cli

lint: markdownlint rubocop


verify-specs: bundle
	STONE_PRELUDE='docs/specs/prelude.stone' bin/stone verify --debug docs/specs/*.md

rspec: bundle
	bundle exec rspec

setup-overcommit: .git/hooks/overcommit-hook

bundle:
ifneq ($(BUNDLE_CHECK), 0)
	bundle
endif

Gemfile.lock: Gemfile
	bundle

.git/hooks/overcommit-hook: .overcommit.yml
	bundle exec overcommit --install
	bundle exec overcommit --sign
	bundle exec overcommit --sign pre-commit

rubocop:
	bundle exec rubocop .

markdownlint:
	markdownlint *.md docs

.PHONY: all setup console lint verify-specs rspec setup-overcommit bundle rubocop markdownlint
