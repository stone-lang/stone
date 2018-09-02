Basics
======


Comments
--------

Comments are available in 2 varieties.
Perl-style comments begin with a `#` and continue to the end of the line.

~~~ stone
123 # This is a comment.
#= Number.Integer(123)
~~~

~~~ stone
# This is a comment.
123
#= Number.Integer(123)
~~~

~~~ stone
# This is a comment.
123
# This is another comment.
#= Number.Integer(123)
~~~

C-style block comments start with `/*` and end with `*/`.
Note that C-style comments cannot be nested;
the first `*/` will always end the comment and return to processing code.

~~~ stone
123 /* This is a comment. */
#= Number.Integer(123)
~~~

~~~ stone
1 /* This is a comment. */ + 2
#= Number.Integer(3)
~~~

~~~ stone
123 /* This is a
       multi-line
       comment.
     */
#= Number.Integer(123)
~~~


Variables
---------

~~~ stone
a := 123
a
#= Number.Integer(123)
~~~

~~~ stone
a := 123
b
#! UndefinedVariable: b
~~~


Conditionals
------------

Stone uses blocks to indicate code that *might* run later.
This allows `if` to be written as a function.
The `then` clause of an `if` conditional is passed as the 2nd argument.

~~~ stone
if(TRUE, { 1 })
#! Number.Integer(1)
~~~

The `if` function takes an optional 3rd argument, which acts as the `else` clause.

~~~ stone
if(2 < 1, { "2 is less than 1" }, { "2 is NOT less than 1" })
#! Text("2 is NOT less than 1")
~~~
