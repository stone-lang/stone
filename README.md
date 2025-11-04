# The Stone Programming Language

Stone is a multi-paradigm programming language. It combines the ideas of object-oriented,
functional, and actor-based languages. It is a typed language, with immutability by default.

This is a *very* new language, but I've been thinking about the design of the language for
quite some time. The design documents can be found in [/docs/design](docs/design/README.md).

## Goals

I have several goals that I keep in mind when designing and implementing Stone. My top-level goals are:

- Have fun learning and creating
- See if I can make something useful
- Correctness

For more details, see the [Goals](docs/design/Goals.md) in the design documents.

## Specifications

The language is described in Markdown, with code blocks showing example code.
The code blocks also show the expected result of evaluating the code.
This is also used as the language specification —
all the example code is checked to ensure that it evaluates to the expected result.
These can be found in [docs/specs](docs/specs/README.md).

## Building

We're using standard `make` to build the system.

Currently, we're using Ruby for all pieces of Stone, so you won't need to actually run a build step to get a `stone` binary.

You can verify that the specs are all passing:

~~~ shell
make verify-specs
~~~

## Running

Binaries are located in the bin directory:

- `stone`
    - `stone parse` - Output parse tree
    - `stone ast` - Output AST (abstract syntax tree)
    - `stone mlir` - Output MLIR (multi-level intermediate representation)
    - `stone llir` - Output LLIR (low-level intermediate representation)
    - `stone compile` - Compile to an executable
    - `stone run` - Compile to an executable and run it
    - `stone eval` - Output the result of each top-level expression (non-interactive REPL)
    - `stone verify` - Verify that results of top-level expressions match expectations in comments
    - `stone repl` - Accept interactive manual input, and show the result of each top-level expression (default if no arguments are given)
    - `stone specs` - Run tests/specs
    - `stone build` - Compile an entire project
    - `stone lint` - Check Stone code for issues
    - `stone format` - Format Stone code
    - `stone lsp` - Start the Language Server Protocol service
    - `stone publish` - Publish to package repository
    - `stone deps` - Manage project dependencies (package manager)

Note that most of these commands are still under development — or development has not even started on them yet.

## Changelog

See the [CHANGELOG](CHANGELOG.md) file for information about what changes have been made in each release.

## License

Stone is released under the MIT license. See the [LICENSE](/LICENSE.txt) file for details.

## Thanks

Thanks to some advice from my friends in the STL Polyglots group in selecting the name.
Especially Deech.

Thanks to Claude, ChatGPT, and GitHub Copilot for lots of good advice.
And lots of frustration!
