# AGENTS.md

This file provides guidance to AI agents (such as Claude Code) when working with code in this repository.

## AI Agent Session Context

**IMPORTANT**: When starting a new session, verify your environment first:

1. **Working Directory**: Sessions should run from `~/Work/stone` (the main repository, NOT a worktree)
2. **Default Branch**: `0.10` (current development branch)
3. **Session Verification**: At session start, check:
   - Current directory: `pwd` (should be `~/Work/stone`)
   - Current branch: `git --no-pager branch --show-current` (should be `0.10`)
   - Uncommitted changes: `git --no-pager status --short`

**If you find yourself in a worktree directory** (like `~/.claude-worktrees/stone/*`):
- Inform the user about the location mismatch
- Ask whether to:
  - Continue in the worktree (for isolated feature work on that branch)
  - Switch context to the main repository (for work on the 0.10 branch)

**Git worktrees**: This repository uses git worktrees for parallel branch work. The main repository is at `~/Work/stone` and worktrees are in `~/.claude-worktrees/stone/`. When working with git commands across repositories, use `--git-dir` and `--work-tree` flags to specify the target repository explicitly.

### Repository Dependencies

Grammy is linked locally during development:
- Location: `~/Work/Code/grammy`
- Configured in `Gemfile`: `gem "grammy", path: "~/Work/Code/grammy"`
- Configured in `.bundle/config` for local development

When working on Stone features that need Grammy changes:
1. Make the Grammy changes first
2. Test them in Stone
3. Commit Grammy and Stone changes separately

## Project Overview

Stone is a multi-paradigm programming language combining object-oriented, functional, and actor-based paradigms. It's a typed language with immutability by default, currently in very early development. The implementation is written in Ruby and uses LLVM for code generation.

I'm working on 2 repos simultaneously:

- Stone (~/Work/stone)
- Grammy (~/Work/Code/grammy)

Grammy is a dependency of Stone. Stone is my primary project; Grammy is just a piece of Stone that could be used independently.

We can fix or add to Grammy if we need to to unblock Stone. We can look at Stone to see how we can improve Grammy.

**IMPORTANT**: Before you start working, determine if the request involves Grammy or Stone (or both). More likely than not, it'll be Stone. Use context to decide; do not rely on looking at the current directory.

We use `.bundle/config` in Stone to link to the "live" version of Grammy in development.

## Important Notes

- Main branch for PRs: **master** (not `main` yet, as of this writing)
- Current development branch: **0.10**
- Grammy parser is a local dependency at ../Code/grammy (not published to RubyGems)
- Vendor directory contains bundled dependencies
- This is an early-stage project - many planned features are not yet implemented

## Workflow

First, we'll discuss the problem and its requirements, what our options are, and a rough outline our implementation plan.

Once I'm happy with the plan, I will ask you to write the tests. We're working in a TDD style, where we write tests before implementing the feature. I consider the tests to be executable specifications, and will use "tests" and "specs" interchangeably.

When asked to write tests, **DO NOT** write the implementation. I will need to validate the specifications/tests first.

Because of the speed that AI agents work, I don't need to be involved in the full TDD cycle for each test, but I definitely want to understand the tests/specs before thinking about the implementation.

I'll tell you to continue once I'm happy with the tests. Proceed with the implementation. If you find that we need to change any of the tests, let me know, and we will discuss the options.

When the tests pass, check to see if there are any refactoring opportunities. I'm a fan of "merciless refactoring". How simple can we make the code, while still passing the tests? How can we make the code more readable and maintainable? (Great answers: keep it simple; use intention-revealing names.) I plan to have mutation testing in place soon, to encourage this even more.

Double-check to ensure the code is following security best practices, coding best practices. Make sure linting is passing.

Once that's done, give yourself a code review. Use a subagent, if possible. Correct any issues identified.

Then suggest a concise commit message, following the directions below. Suggest multiple commits if it's appropriate to keep small atomic commits. I want to be able to use `git bisect` without worries, and I want atomic commits to make rollbacks safer and easier. Have the commit(s) and commit message(s) approved before making the commits. TODO: Please help me figure out how to trust allowing the AI agent to make commits, then PRs. I can always squash or interactively rebase to clean things up after the fact. Especially with AI's help. Especially if I do code reviews.

Please ask me questions, challenge my assumptions, and make suggestions at any time. Suggest any improvements to the approach, the code structure, or organization. Suggest things you learned that would be good to add to the AGENTS.md or CLAUDE.md file, or some other file.

## ⚠️ MANDATORY APPROVAL CHECKPOINTS

Before proceeding past any of these points, you MUST have explicit user approval:

1. **Before writing tests** - Discuss the problem, requirements, and approach first
2. **Before writing implementation** - Tests must be reviewed and approved
3. **Before committing** - Code review and commit message must be approved

If the user gives a task that seems straightforward, STILL discuss the approach first.
Do not assume approval. Look for explicit phrases like "go ahead", "proceed", "continue", "looks good", etc.

When in doubt, ask: "Should I proceed with [next step]?"

## Simple Design

Follow Kent Beck's 4 Rules Of Simple Design:

1. Passes all tests
2. Reveals intention
3. No duplication
    - Be wary of hidden duplication like parallel class hierarchies
4. Fewest elements

Write with empathy for future readers of the code we commit. Remember, that's mostly going to be *us*. The ability to make future changes is the key metric we should shoot for, even though that's very difficult to actually measure. We want to minimize anything that slows the pace of delivering future features.

Use immutable values and pure functions whenever possible. They are easier to reason about, reducing potential for bugs.

## Build and Test Commands

### Setup and Dependencies

```bash
make setup      # Install all dependencies (LLVM, Ruby gems, Node/Bun packages)
make deps       # Install Ruby dependencies only (bundle install)
bundle install  # Install Ruby gems (runs automatically if needed)
```

### Testing

```bash
LLVM_PREFIX="$(shell brew --prefix llvm 2>/dev/null || { [ -d /usr/lib/llvm-21 ] && echo /usr/lib/llvm-21; } || where llvm 2>/dev/null || echo)"
DYLD_LIBRARY_PATH="$(LLVM_PREFIX)/lib:$(DYLD_LIBRARY_PATH)"
make test       # Run all tests
make specs      # Alias for make test
make rspec      # Run RSpec tests directly
mise exec -- bundle exec rspec                    # Run all specs
mise exec -- bundle exec rspec spec/path/to/file # Run specific spec file
```

### Linting

```bash
LLVM_PREFIX="$(shell brew --prefix llvm 2>/dev/null || { [ -d /usr/lib/llvm-21 ] && echo /usr/lib/llvm-21; } || where llvm 2>/dev/null || echo)"
DYLD_LIBRARY_PATH="$(LLVM_PREFIX)/lib:$(DYLD_LIBRARY_PATH)"
make lint       # Run all linters (RuboCop + markdownlint)
make rubocop    # Run RuboCop only
make markdownlint # Run markdownlint only
bundle exec rubocop -a .            # Auto-fix Ruby issues
```

### Console/REPL

```bash
make console    # Start Pry console with Stone and Grammy loaded
```

### Git Commands

**IMPORTANT**: When running git commands, **always** use the `--no-pager` flag, or else the results may be paginated:

```bash
git --no-pager status
git --no-pager log
git --no-pager diff
# etc.
```

This is **necessary** because `git` is configured to use a pager (`delta`) which can cause timeouts when run by AI agents.

### Common Git Operations

**Amending older commits** (when they haven't been pushed):
```bash
# Create a fixup commit
git commit --fixup <commit-hash>

# Auto-squash the fixup into the original commit
GIT_SEQUENCE_EDITOR=true git rebase --autosquash -i <commit-hash>^
```

**Checking commit authorship** (before amending):
```bash
git log -1 --format='%an %ae'
```

**Working across repositories** (main repo and worktrees):
```bash
git --git-dir=~/Work/stone/.git --work-tree=~/Work/stone <command>
```

## Commits

Every non-WIP commit that I push to upstream should pass CI (all tests and linting, via `make ci`).

When making a commit, commit **only** the files that you (the AI agent) have changed. Do **not** commit changes that were there before your changes were made.

Keep commit messages concise.

When creating commits for work done with AI assistance, add a co-author trailer to the commit message, similar to pair programming convention:

```text
Co-authored-by: Claude (Anthropic) <claude@anthropic.com>
```

GitHub will recognize the `Co-authored-by:` trailer and show both authors on the commit.

### Commit Checklist

We must ensure that all of these are completed before making a (non-WIP) commit:

- CI passes locally (`make ci`)
    - runs `make specs`
    - runs `make lint`
- you have code reviewed your changes and made appropriate updates
    - use of good intention-revealing names?
    - any security concerns?
    - any performance concerns?
    - any documentation concerns?
- we have done enough refactoring
    - we've considered changes to the app architecture
    - is everything DRY?
        - is there obvious duplication
- check TODOs that can/should be updated
- CHANGELOG has been updated
- version number has been updated, if appropriate
- the changes have been reviewed by the user

### Organizing Multiple Changes

When you have multiple uncommitted changes:
1. Run `make ci` first to ensure everything passes
2. Group related changes logically:
   - Infrastructure/build changes together
   - Related refactorings together (consider amending if recent)
   - Documentation updates together
   - Feature additions separately
3. Use `git add <specific-files>` to stage related changes
4. Consider whether refactorings can be squashed into recent related commits
5. Create atomic commits that can pass CI independently

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

- **spec/** - Specifications that serve dual purpose:
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
- mise (fallback): Configured in `.tool-versions` and `.mise.toml`

Environment setup in `.mise.toml` automatically configures `LLVM_PREFIX`, `PATH`, and `DYLD_LIBRARY_PATH`.

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
- Line length: 120 characters
- Block style: Use `{}` for functional blocks that return values, `do/end` otherwise
- Exceptions for RSpec and grammar/transform rules (use {} for `rule`, `let`, `expect`)
- Non-ASCII identifiers and comments are allowed
- Use inline `private def` instead of having a `private` section

### Testing with RSpec

- RSpec configuration in .rspec loads lib/ automatically
- Requires debug and pry for debugging
- Pattern: `spec/**/*_spec.rb`
- Tests also serve as executable specifications

#### Spec Organization

Specs are organized into unit tests, language specification tests, and CLI tests:

1. **spec/unit/** - Unit tests for individual components
   - `unit/parser/` - Parser/grammar tests (parse tree structure)
   - `unit/ast/` - AST node tests (node behavior, LLVM IR generation)
   - `unit/transform/` - Transformation tests (parse tree → AST)
   - `unit/api/` - Stone module API tests (Stone.parse, Stone.eval, etc.)

2. **spec/language/** - Language specification tests
   - Tests complete parse → transform → compile → evaluate flow
     - But not the CLI code
   - Documents language semantics with executable examples
   - Serves as both spec and documentation

3. **spec/cli/** - End-to-end tests that include CLI commands


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

## Documentation Standards

When creating documents in `docs/`:

- Do NOT include time estimates, effort assessments, or difficulty ratings
- Do NOT include subjective goals, priorities, or judgement-based criteria
- Focus on technical facts: current state, problems, solutions, implementation steps
- Include code examples, file paths, and concrete technical details
- The human developer is the sole decision-maker for priorities and effort allocation

## Issue Tracking

**IMPORTANT**: When you encounter any warning, deprecation, or other issue during your work that is outside the scope of your current task, add a short synopsis to ISSUES.md and mention it to the user.

## AI Agent Best Practices

### Before Making Changes
- Always read files before editing them (required by tools)
- Understand existing patterns before suggesting new ones
- Check recent commits to understand context and style

### During Work
- Use TodoWrite to track multi-step tasks
- Mark todos as in_progress before starting work
- Mark todos as completed immediately after finishing
- Keep exactly ONE todo in_progress at a time

### Session Management
- Verify git commands use `--no-pager` flag
- Avoid `cd` commands; use absolute paths or git flags instead
- Check for uncommitted changes at session start
- Clarify which repository (Stone vs Grammy) before starting work

## Troubleshooting

### Shell/Directory Issues

If you encounter `cd` failures or mise/zoxide errors when trying to change directories:
- Use absolute paths with git `--git-dir` and `--work-tree` flags instead
- The shell configuration may interfere with `cd` commands in AI agent sessions

### SSL Certificate Issues

If RuboCop fails to fetch remote config due to SSL errors:
- Temporary workaround is in `lib/disable_ssl_verify.rb`
- Loaded via `RUBYOPT` in Makefile's rubocop target

## Final Thoughts

Don't forget to use the `--no-pager` flag for `git`!

Don't forget to stop and ask for required approvals before moving on to the next task in the workflow.
