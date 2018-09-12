The Stone Programming Language
==============================

Stone is a multi-paradigm programming language. It combines the ideas of object-oriented,
functional, and actor-based languages. It is a typed language, with immutability by default.

This is a *very* new language, but I've been thinking about the design of the language for
quite some time. The design documents can be found in [docs/design](docs/design).

The language is described in Markdown, with code blocks showing example code.
The code blocks also show the expected result of evaluating the code.
This is also used as the language specification —
all the example code is checked to ensure that it evaluates to the expected result.
These can be found in [docs/specs](docs/specs).


Building
--------

We're using standard `make` to build the system.

Currently, we're using Ruby for all pieces of Stone,
so you won't need to actually run a build step to get a `stone` binary.

You can verify that the specs are all passing:

~~~ shell
make verify-specs
~~~


Running
-------

Binaries are located in the `bin` directory:

* `stone` - the main executable
    * `stone eval` - output the result of each top-level expression
    * `stone repl` - accept manual input, and show the result of each line
    * `stone verify` - check that results of top-level expressions match expectations in comments


License
-------

Stone is released under the MIT license. See the [license](/LICENSE) file for details.


Thanks
------

Thanks to some advice from my friends in the STL Polyglots group in selecting the name.
Especially Deech.
