Literals
========

When writing a program, we frequently have to specify literal values.
Literal values are values (numbers, text, etc.) that are specified within the program itself,
as opposed to values that are provided as input to the program, or computed by the program.


Integers
--------

The simplest literal is an integer.
We normally specify integers in decimal format:

~~~ stone
123
#= Number.Integer(123)
~~~

We can specify negative numbers, by prefixing with the `-` character.

~~~ stone
-123
#= Number.Integer(-123)
~~~

Note that the `-` is part of the integer literal; there is no unary `-` operator.
