# AGENTS.md

This file provides guidance to AI agents (such as Claude Code) when working with code in this repository.

## Project Overview

Stone is a multi-paradigm programming language combining object-oriented, functional, and actor-based paradigms. It's a typed language with immutability by default, currently in very early development. The implementation is written in Ruby and uses LLVM for code generation.

## Build and Test Commands

### Setup and Dependencies

```bash
make setup      # Install all dependencies (LLVM, Ruby gems, Node/Bun packages)
make deps       # Install Ruby dependencies only (bundle install)
bundle install  # Install Ruby gems (runs automatically if needed)
```

### Testing

```bash
make test       # Run all tests
make specs      # Alias for make test
make rspec      # Run RSpec tests directly
bundle exec rspec                    # Run all specs
bundle exec rspec specs/path/to/file # Run specific spec file
```

### Linting

```bash
make lint       # Run all linters (RuboCop + markdownlint)
make rubocop    # Run RuboCop only
make markdownlint # Run markdownlint only
bundle exec rubocop .               # Lint Ruby code
bundle exec rubocop -a .            # Auto-fix Ruby issues
```

### Console/REPL

```bash
make console    # Start Pry console with Stone and Grammy loaded
bundle exec pry -I lib -r stone -r grammy
bundle exec irb -I lib -r stone -r grammy
```

### Git Commands

When running git commands, always use the `--no-pager` flag to prevent pagination issues:

```bash
git --no-pager status
git --no-pager log
git --no-pager diff
# etc.
```

This is necessary because the repository owner has git configured to use a pager (delta) which can cause timeouts when run by AI agents.

## Architecture

### Project Structure

- **lib/extensions/** - Ruby core class extensions (String, Integer, Boolean, Class, Module, etc.)
  - Provides Scheme-style methods like `first`, `rest`, `tail` on String
  - Extensions use monkey-patching (TODO: migrate to refinements via `pretty_ruby` gem)

- **lib/stone/** - Main Stone language implementation
  - **lib/stone/ast/** - Abstract Syntax Tree node classes
    - Each AST node defines `to_llir()` method for LLVM IR generation
    - Example: `IntegerLiteral` wraps integer values for compilation

- **lib/literals/** - Support for Stone language literals (currently minimal)

- **specs/** - Specifications that serve dual purpose:
  - Test suite (RSpec tests)
  - Language specification (executable documentation)

### Parser and Grammar

Stone uses the Grammy parser generator (local dependency at ../Code/grammy). Parser extensions are in lib/extensions/parslet.rb:
- `rule!` - Define grammar rules that output AST nodes
- `parens()`, `curly_braces()` - Helper methods for bracketed expressions

### LLVM Integration

Stone compiles to LLVM IR using the ruby-llvm gem (v21+). LLVM is managed via:
- Homebrew (macOS): `brew install llvm@21` or `brew install llvm`
- apt-get (Linux): `apt-get install llvm-21-dev llvm-21`
- mise (fallback): Configured in .tool-versions and .mise.toml

Environment setup in .mise.toml automatically configures LLVM_PREFIX, PATH, and DYLD_LIBRARY_PATH.

### Planned Stone CLI Commands

The `stone` binary (not yet implemented) will support:
- `stone parse` - Output parse tree
- `stone ast` - Output abstract syntax tree
- `stone eval` - Non-interactive REPL (evaluate and print results)
- `stone verify` - Verify code against specifications in comments
- `stone repl` - Interactive REPL (default)
- `stone compile` - Compile to executable
- `stone run` - Compile and run
- Additional commands: mlir, llir, specs, build, lint, format, lsp, publish, deps

## Development Practices

### Code Style

- RuboCop configuration inherits from https://raw.githubusercontent.com/booch/config_files/master/ruby/rubocop.yml
- Line length: 160 characters
- Block style: Use `{}` for functional blocks that return values, `do/end` otherwise
- Exceptions for RSpec and grammar/transform rules (use {} for `rule`, `let`, `expect`)
- Non-ASCII identifiers and comments are allowed

### Testing with RSpec

- RSpec configuration in .rspec loads lib/ automatically
- Requires debug and pry for debugging
- Pattern: `specs/**/*_spec.rb`
- Tests also serve as executable language specifications

#### Spec Organization

Specs are organized into unit tests, language specification tests, and CLI tests:

1. **specs/unit/** - Unit tests for individual components
   - `unit/parser/` - Parser/grammar tests (parse tree structure)
   - `unit/ast/` - AST node tests (node behavior, LLVM IR generation)
   - `unit/transform/` - Transformation tests (parse tree → AST)
   - `unit/api/` - Stone module API tests (Stone.parse, Stone.eval, etc.)

2. **specs/language/** - Language specification tests
   - Tests complete parse → transform → compile → evaluate flow
     - But not the CLI code
   - Documents language semantics with executable examples
   - Serves as both spec and documentation

3. **specs/cli/** - End-to-end tests that include CLI commands


#### Writing Specs

- Use descriptive test names that explain behavior
- Unit tests should test one component in isolation
- Integration tests verify components work together
- Integration tests should read like documentation of the Stone language
- Include edge cases and boundary conditions
- Test both success and failure paths where applicable

### Pre-commit Workflow

When using the `/pre-commit` command:
1. Check for related uncommitted changes
2. Review staged files for errors, security issues, readability
3. Verify test coverage
4. Check for refactoring opportunities
5. Run tests for staged code
6. Show staged changes summary
7. Suggest commit message

### Tool Versions

Managed by mise and .tool-versions:
- Ruby 3.4.7
- Bun 1.3
- LLVM 21

## Important Notes

- Main branch for PRs: **master** (not main)
- Current development branch: **0.10**
- Grammy parser is a local dependency at ../Code/grammy (not published to RubyGems)
- Vendor directory contains bundled dependencies
- This is an early-stage project - many planned features are not yet implemented

## Documentation Standards

When creating documents in `docs/`:

- Do NOT include time estimates, effort assessments, or difficulty ratings
- Do NOT include subjective goals, priorities, or judgement-based criteria
- Focus on technical facts: current state, problems, solutions, implementation steps
- Include code examples, file paths, and concrete technical details
- The human developer is the sole decision-maker for priorities and effort allocation
