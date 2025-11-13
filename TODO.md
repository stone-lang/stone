# TODO

## Setup

- [x] basic README
- [x] license
- [x] TODO list
- [x] GitHub organization
- [x] GitHub repo
- [x] buy domain
- [ ] GitHub pages
- [ ] point domain at GitHub pages
- [ ] code of conduct
- [ ] `jj`
    - [ ] root directory only contains worktrees (git --bare; git worktree add)
        - [ ] and maybe support files (`.gitignore`, `.vscode`, etc)
        - [ ] add git aliases for `worktree add -b` and `switch`
- [x] `.gitignore`
- [x] `.tool-versions`
- [x] `.mise.toml`
- [x] `Gemfile`
- [x] `.rubocop.yml`
- [x] `.markdownlint.yml`
- [x] `.rspec`
- [ ] `.irbrc`
- [ ] `.pryrc`

## Documentation

- [x] comprehensive `README` (and keep it updated)
    - [x] intro
    - [ ] table of contents
    - [ ] features
    - [ ] installation
    - [ ] usage
    - [x] tests
    - [ ] contributing
    - [ ] badges (see [shields.io](https://shields.io/))
        - [ ] version
        - [ ] license
        - [ ] build status (https://github.com/OWNER/REPO/actions/workflows/WORKFLOW/badge.svg
        )
        - [ ] test coverage
        - [ ] dependencies status
- [x] `TODO` (and keep it updated)
- [ ] `CHANGELOG` (and keep it updated)
- [x] `LICENSE` file (and keep it updated)
- [ ] code of conduct
- [ ] FAQ

## Automation

- [x] `Makefile` for "standard" common tasks
- [ ] `Rakefile` for "standard" common tasks for Ruby projects
    - [ ] update version
        - [ ] verify that CHANGELOG is updated
    - [ ] upload to RubyGems
    - [ ] update dependencies
        - [ ] Ruby
        - [ ] gems
        - [ ] RuboCop (see if any rules need updated config)
- [ ] CI/CD setup (GitHub Actions)
- [x] linting
    - [x] RuboCop
    - [x] markdownlint
    - [ ] Reek
    - [ ] bundler-audit
- [ ] test coverage
- [ ] code quality metrics
- [ ] git hooks (pre-commit, pre-push, etc)
    - [ ] linting
    - [ ] tests
    - [ ] security checks (bundle audit, etc)
- [ ] ISSUES_TEMPLATE
- [ ] PULL_REQUEST_TEMPLATE
- [ ] `.editorconfig`

## Grammar

- [x] Start on parser and grammar
    - Took time out to write Grammy
- [ ] Self-hosting compiler (this one is WAY off)

## Design Docs

- [ ] Purpose
- [ ] Goals
- [ ] Features

## Specifications (verified by tests)

- [ ] automate testing of specifications
- [x] literals
    - [ ] Boolean
    - [x] integer
    - [ ] string
    - [ ] pair
    - [ ] fixed-point
    - [ ] rational
- [ ] functions
    - [ ] function call
    - [ ] function definition
    - [ ] variable args
- [ ] operators
    - [ ] Boolean
    - [ ] comparison
    - [ ] arithmetic
    - [ ] mixed operators (gives an error in most cases)
    - [ ] parentheses
    - [ ] text
- [ ] classes
    - [ ] class definition
    - [ ] object instantiation
    - [ ] property definition
    - [ ] property access
    - [ ] computed property definition
    - [ ] computed property access
    - [ ] class method definition
    - [ ] class method call
    - [ ] method definition
    - [ ] method call
    - [ ] constructor
    - [ ] destructor
- [ ] collections
    - [ ] List
    - [ ] Map
    - [ ] Range
    - [ ] Deque
    - [ ] Stack
    - [ ] Queue
    - [ ] Set
    - [ ] Queue.Priority

## Gem

- [ ] create a gem
    - [ ] `gemspec`
    - [ ] publish to RubyGems
- [ ] CLI
    - [ ] `bin/stone`
    - [ ] install with the gem
    - [ ] `--help`
    - [ ] `--version`
    - [ ] `--json`
    - [ ] `<grammar_file>` to output a serialized parse tree, with input from `STDIN`

## Support

- [ ] VS Code configuration
    - [ ] tasks (`launch.json`)
    - [ ] recommended extensions
- [ ] snippets
- [ ] Language Server (LSP)
    - [ ] syntax highlighting
    - [ ] linting
    - [ ] symbol info (docs, go to definition, etc)
    - [ ] code completion
    - [ ] formatting
    - [ ] refactoring
