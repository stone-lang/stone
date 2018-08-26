Literals
========

When writing a program, we frequently have to specify literal values.
Literal values are values (numbers, text, etc.) that are specified within the program itself,
as opposed to values that are provided as input to the program, or computed by the program.


Integers
--------

The simplest literal is an integer.
Integers include all positive and negative whole numbers, plus 0.
Integers do not contain fractional portions.

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

NOTE: The `-` prefix is part of the integer literal; there is no unary `-` operator.

We can also include an optional `+` prefix:

~~~ stone
+123
#= Number.Integer(123)
~~~

Leading zeros are allowed:

~~~ stone
00123
#= Number.Integer(123)
~~~

Note that negative and positive 0 give the same result:

~~~ stone
0
#= Number.Integer(0)
~~~

~~~ stone
00000
#= Number.Integer(0)
~~~

~~~ stone
-0
#= Number.Integer(0)
~~~

~~~ stone
+0
#= Number.Integer(0)
~~~

Stone allows arbitrarily large numbers. The only limits are memory and computation time.
TODO: Arbitrary-precision numbers are not yet implemented; add specs when they are.
