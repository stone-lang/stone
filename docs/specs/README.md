Stone Specifications
====================

These are the executable specifications for the Stone programming language.

* [Basics](Basics.md)
* [Literals](Literals.md)
* [Expressions](Expressions.md)


## Conventions

For every code block, expected results will be included, prefixed with `#=`.
In some cases, there will be an expected exception, instead of an expected result —
these will be prefixed with `#!` instead of `#=`.


## Running

You can test that all these specifications are being met by running the following
(from the top-level directory):

~~~ shell
make verify-specs
~~~

Verification will run automatically any time a commit is made to the `master` branch,
to ensure that the behavior of Stone always matches the specifications.
