SHELL := /bin/bash
BUNDLE_CHECK := $(shell bundle check >/dev/null ; echo $$?)


verify-specs: bundle
	bin/stone verify docs/specs/*.md

setup: .git/hooks/overcommit-hook


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
