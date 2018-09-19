Basics
======


Comments
--------

Comments are available in 2 varieties.
Perl-style comments begin with a `#` and continue to the end of the line.

~~~ stone
123 # This is a comment.
#= Number.Integer(123)

# This is a comment.
456
#= Number.Integer(456)

# This is a comment.
789
# This is another comment.
#= Number.Integer(789)
~~~

C-style block comments start with `/*` and end with `*/`.
Note that C-style comments cannot be nested;
the first `*/` will always end the comment and return to processing code.

~~~ stone
123 /* This is a comment. */
#= Number.Integer(123)

1 /* This is a comment. */ + 2
#= Number.Integer(3)

456 /* This is a
       multi-line
       comment.
     */
#= Number.Integer(456)
~~~


Variables
---------

~~~ stone
a := 123
a
#= Number.Integer(123)

b
#! UndefinedVariable: b

c := "Hello"
if(TRUE, { c })
#= Text("Hello")
~~~


Conditionals
------------

Stone uses blocks to indicate code that *might* run later.
This allows `if` to be written as a function.
The `then` clause of an `if` conditional is passed as the 2nd argument.
The `if` function takes an optional 3rd argument, which acts as the `else` clause.

There's also `unless`, which is the same as `if`, but with `TRUE` and `FALSE` cases reversed.

~~~ stone
if(TRUE, { 1 })
#= Number.Integer(1)

unless(FALSE, { 123 })
#= Number.Integer(123)

if(2 < 1, { "2 is less than 1" }, { "2 is NOT less than 1" })
#= Text("2 is NOT less than 1")

x := 1
unless(x == 1, { "there are x things" }, { "there is 1 thing" })
#= Text("there is 1 thing")

if(TRUE)
#! ArityError: 'if' expects 2 or 3 arguments, got 1

if(TRUE, 1)
#! TypeError: 'if' argument 'then' must be a block

if(TRUE, { 1 }, 2)
#! TypeError: 'if' argument 'else' must be a block
~~~
