SHELL := /bin/bash
BUNDLE_CHECK := $(shell bundle check >/dev/null ; echo $$?)


setup: .git/hooks/overcommit-hook

verify-specs: bundle setup
	bin/stone verify docs/specs/*.md

bundle:
ifneq ($(BUNDLE_CHECK), 0)
	bundle
endif

Gemfile.lock: Gemfile
	bundle

.git/hooks/overcommit-hook: bundle
	bundle exec overcommit --install
	bundle exec overcommit --sign
	bundle exec overcommit --sign pre-commit
