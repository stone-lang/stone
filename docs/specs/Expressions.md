Expressions
===========

When writing a program, we often use expressions of various kinds to compute values.


Operations
----------

Operations are computations that involve a symbolic _operator_.
Operations generally look like mathematical notation.
In addition to the operator, an operation works with 1 or more _operands_.

Most operations in Stone are _infix_, meaning that the operator comes _between_ the operands.
Stone *requires* white space around infix operators.

A few operations are _unary_, meaning that the operator takes a single operand.
All unary operators in Stone are _prefix_, meaning that the operator comes before the operand.
No white space is allowed between a prefix operator and its operand.

Operators may be repeated:

~~~ stone
1 + 2 + 3
#= Number.Integer(6)
~~~

~~~ stone
2 * 3 * 4
#= Number.Integer(24)
~~~

However, operators may *not* be mixed, without using parentheses.
Most programming languages have operator precedence rules; Stone does not.
Operator precedence adds complexity to a language, without much value.
Most importantly, operator precedence adds complexity to what you have to learn about a language.

~~~ stone
1 + 2 * 3
#! MixedOperatorsError: Add parentheses where appropriate.
~~~

~~~ stone
(1 + 2) * 3
#= Number.Integer(9)
~~~

~~~ stone
1 + (2 * 3)
#= Number.Integer(7)
~~~

There are only a few exceptions to the mixed operators rule:

~~~ stone
1 + 2 - 3
#= Number.Integer(0)
~~~

~~~ stone
1 - 2 + 3 - 4
#= Number.Integer(-2)
~~~

~~~ stone
1 < 2 <= 3
#= Boolean(Boolean.TRUE)
~~~

~~~ stone
3 >= 4 > 3
#= Boolean(Boolean.FALSE)
~~~


### Equality Operators

Stone has the normal infix operators that you'd expect for equality and inequality.

~~~ stone
TRUE == TRUE
#= Boolean(Boolean.TRUE)
~~~

~~~ stone
TRUE != FALSE
#= Boolean(Boolean.TRUE)
~~~

~~~ stone
123 == 123
#= Boolean(Boolean.TRUE)
~~~

~~~ stone
123 != 123
#= Boolean(Boolean.FALSE)
~~~

~~~ stone
123 != 456
#= Boolean(Boolean.TRUE)
~~~

~~~ stone
"yes" != "Yes"
#= Boolean(Boolean.TRUE)
~~~

~~~ stone
"Yes" == "Yes"
#= Boolean(Boolean.TRUE)
~~~

~~~ stone
FALSE == 123
#= Boolean(Boolean.FALSE)
~~~

~~~ stone
"123" == 123
#= Boolean(Boolean.FALSE)
~~~

~~~ stone
"123" ≠ 123
#= Boolean(Boolean.TRUE)
~~~


### Comparison Operators

Stone has the normal infix operators that you'd expect for greater-than and less-than.

~~~ stone
1 < 2
#= Boolean(Boolean.TRUE)
~~~

~~~ stone
2 <= 2
#= Boolean(Boolean.TRUE)
~~~

~~~ stone
2 <= 3
#= Boolean(Boolean.TRUE)
~~~

~~~ stone
1 > 2
#= Boolean(Boolean.FALSE)
~~~

~~~ stone
2 >= 2
#= Boolean(Boolean.TRUE)
~~~

~~~ stone
3 >= 2
#= Boolean(Boolean.TRUE)
~~~

~~~ stone
1 < 2
#= Boolean(Boolean.TRUE)
~~~

~~~ stone
2 <= 2
#= Boolean(Boolean.TRUE)
~~~

~~~ stone
2 ≤ 2
#= Boolean(Boolean.TRUE)
~~~

~~~ stone
1 ≥ 2
#= Boolean(Boolean.FALSE)
~~~

~~~ stone
"abc" <= "abc"
#= Boolean(Boolean.TRUE)
~~~

~~~ stone
"abc" <= "abcd"
#= Boolean(Boolean.TRUE)
~~~

One thing that's relatively unique to Stone is that you can chain comparison operators.

~~~ stone
1 < 2 < 3
#= Boolean(Boolean.TRUE)
~~~

~~~ stone
3 >= 3 >= 2
#= Boolean(Boolean.TRUE)
~~~


### Numeric Operators

Stone has the normal infix numeric operators that you'd expect for addition, subtraction, and multiplication.

~~~ stone
1 + 2
#= Number.Integer(3)
~~~

~~~ stone
1 - 2
#= Number.Integer(-1)
~~~

~~~ stone
2 * 3
#= Number.Integer(6)
~~~


### Boolean Operators

The simplest operation we can perform is Boolean negation (usually pronounced "not").
This is done using the `!` character as a unary prefix operator.

~~~ stone
!TRUE
#= Boolean(Boolean.FALSE)
~~~

~~~ stone
!FALSE
#= Boolean(Boolean.TRUE)
~~~

~~~ stone
!!TRUE
#= Boolean(Boolean.TRUE)
~~~

~~~ stone
!!FALSE
#= Boolean(Boolean.FALSE)
~~~

The `¬` (Unicode "not sign") may also be used:

~~~ stone
¬TRUE
#= Boolean(Boolean.FALSE)
~~~

~~~ stone
¬FALSE
#= Boolean(Boolean.TRUE)
~~~

~~~ stone
¬¬TRUE
#= Boolean(Boolean.TRUE)
~~~

~~~ stone
!¬TRUE
#= Boolean(Boolean.TRUE)
~~~


### Text Operators

We can use the `++` operator to concatenate strings.

~~~ stone
"abc" ++ "def"
#= Text("abcdef")
~~~

~~~ stone
"abc" ++ "def" ++ "ghi"
#= Text("abcdefghi")
~~~
