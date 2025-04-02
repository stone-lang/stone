# The Stone Programming Language

Stone is a multi-paradigm programming language.
It combines the ideas of object-oriented, functional, and actor-based languages.
It is a typed language, with immutability and strictness by default.

This is a *very* new language,
but I've been thinking about the design of the language for quite some time.
The design documents can be found in [docs/design](docs/design).


## Goals

I have several goals that I keep in mind when designing and implementing Stone.
My top-level goals are:

- Have fun
- See if I can make something useful
- Make a general-purpose language
- Keep the language high-level
- Correctness is more important than speed

For more details, see the [Goals](docs/design/Goals.md) in the design documents.


## Specifications

The language is described in Markdown, with code blocks showing example code.
The code blocks also show the expected result of evaluating the code.
This is also used as the language specification —
all the example code is checked to ensure that it evaluates to the expected result.
These can be found in [docs/specs](docs/specs).


## Building

We're using standard `make` to build the system.

Currently, we're using Ruby for all pieces of Stone,
so you won't need to actually run a build step to get a `stone` binary.

You can verify that the specs are all passing:

~~~ shell
make verify-specs
~~~


## Running

Binaries are located in the `bin` directory:

* `stone`
    * `stone eval` - Output the result of each top-level expression (non-interactive REPL)
    * `stone repl` - Accept interactive manual input, and show the result of each top-level expression
    * `stone verify` - Verify that results of top-level expressions match expectations in comments
    * `stone parse` - Output the parse tree


## License

Stone is released under the MIT license. See the [license](/LICENSE.txt) file for details.


## Changelog

See the [changelog](CHANGELOG.md) file for information about what changes have been made in each release.


## Thanks

Thanks to some advice from my friends in the STL Polyglots group in selecting the name.
Especially Deech.

Thanks to ChatGPT and GitHub Copilot for lots of good advice.
