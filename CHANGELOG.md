# Changelog

## Master (unreleased)

Switch to using Grammy as the parser.

### Changed

### Added

### Removed

### Updated

### Fixed

## 0.4 (unreleased)

### Changed

### Added

- make console
- make lint
    - RuboCop
    - markdownlint
    - NOTE: I also have these running as I type in Visual Studio Code
- closures (I believe this is NOT working)
    - NOTE: variables from outer contexts are read-only
        - so you can't use closures to store state
            - I'm not sure this makes any sense
    - upward funarg problem
    - downward funarg problem

### Updated

- update Ruby
- update RuboCop
- lots of refactoring
- cleaned up this CHANGELOG file

### Fixed

- BUG FIX: Source code should show up in `verify` output if there's a comment after it
- make sure AST nodes and values are independent concepts

## 0.3 (2021-??-??)

### Changed

- Allow first argument of `if` / `unless` to be a block
- Layered sub-languages
    - Allow specifying a sub-language to run
- TRUE is greater than FALSE
    - Why?

### Updated

- Update to Ruby 2.7.2 and update all gems
- Document variable/function/method/identifier names in Basics

### Added

- Function application operators (`|>` and `<|`)
- List iteration (map/each)
    - Pass it a 1-argument function
- `unless` function
- Introduce `Null` and `NULL`
- Add version number, retrievable via `--version`

### Fixed

- BUG FIX: `verify` sub-command should return a non-0 exit code if anything fails

## NOTES

- Sections for each release (in order): Changed, Added, Removed, Updated, Fixed

## TODO

- Add missing changes by reviewing commits
    - Make sure 0.3 and 0.4 document all interesting changes
    - Add pre-0.3 changes
- Try to ensure that this document conforms to https://common-changelog.org/
    - I do add an **Updated** section after **Removed**
