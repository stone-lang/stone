SHELL := /bin/bash
BUNDLE_CHECK := $(shell bundle check >/dev/null ; echo $$?)

all: setup verify-specs

setup: setup-overcommit

console:
	bundle exec irb -I src -rubygems -r stone/cli.rb

lint: rubocop


verify-specs: bundle
	bin/stone --debug verify docs/specs/*.md

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
