SHELL := /bin/bash
BUNDLE_CHECK := $(shell bundle check >/dev/null ; echo $$?)


verify-specs: bundle
	bundle exec bin/verify-specs

bundle:
ifneq ($(BUNDLE_CHECK), 0)
	bundle
endif

Gemfile.lock: Gemfile
	bundle
