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

2 * 3 * 4
#= Number.Integer(24)
~~~

Note that when an operator is repeated, the expression is treated as a single operation.
The operator receives all the operands in a single "call".

Operators may *not* be mixed, without using parentheses.
Most programming languages have operator precedence rules; Stone does not.
Operator precedence adds complexity to a language, without much value.
Most importantly, operator precedence adds complexity to what you have to learn about a language.

~~~ stone
1 + 2 * 3
#! MixedOperatorsError: Add parentheses where appropriate

(1 + 2) * 3
#= Number.Integer(9)

1 + (2 * 3)
#= Number.Integer(7)
~~~

There are only a few exceptions to the mixed operators rule:

~~~ stone
1 + 2 - 3
#= Number.Integer(0)

1 - 2 + 3 - 4
#= Number.Integer(-2)

1 < 2 <= 3
#= Boolean(Boolean.TRUE)

3 >= 4 > 3
#= Boolean(Boolean.FALSE)
~~~


### Equality Operators

Stone has the normal infix operators that you'd expect for equality and inequality.

~~~ stone
TRUE == TRUE
#= Boolean(Boolean.TRUE)

TRUE != FALSE
#= Boolean(Boolean.TRUE)

123 == 123
#= Boolean(Boolean.TRUE)

123 != 123
#= Boolean(Boolean.FALSE)

123 != 456
#= Boolean(Boolean.TRUE)

"yes" != "Yes"
#= Boolean(Boolean.TRUE)

"Yes" == "Yes"
#= Boolean(Boolean.TRUE)

FALSE == 123
#= Boolean(Boolean.FALSE)

"123" == 123
#= Boolean(Boolean.FALSE)

"123" ≠ 123
#= Boolean(Boolean.TRUE)
~~~


### Comparison Operators

Stone has the normal infix operators that you'd expect for greater-than and less-than.
One thing that's relatively unique to Stone is that you can chain comparison operators.

~~~ stone
1 < 2
#= Boolean(Boolean.TRUE)

2 <= 2
#= Boolean(Boolean.TRUE)

2 <= 3
#= Boolean(Boolean.TRUE)

1 > 2
#= Boolean(Boolean.FALSE)

2 >= 2
#= Boolean(Boolean.TRUE)

3 >= 2
#= Boolean(Boolean.TRUE)

1 < 2
#= Boolean(Boolean.TRUE)

2 <= 2
#= Boolean(Boolean.TRUE)

2 ≤ 2
#= Boolean(Boolean.TRUE)

1 ≥ 2
#= Boolean(Boolean.FALSE)

"abc" <= "abc"
#= Boolean(Boolean.TRUE)

"abc" <= "abcd"
#= Boolean(Boolean.TRUE)

1 < 2 < 3
#= Boolean(Boolean.TRUE)

3 >= 3 >= 2
#= Boolean(Boolean.TRUE)
~~~


### Numeric Operators

Stone has the normal infix numeric operators that you'd expect for addition, subtraction, and multiplication.

~~~ stone
1 + 2
#= Number.Integer(3)

1 - 2
#= Number.Integer(-1)

2 * 3
#= Number.Integer(6)

identity(1) + identity(2)
#= Number.Integer(3)
~~~

Stone is perhaps unique in having symbolic minimum and maximum operators.
The `<!` operator returns the minimum of the operands.
The `>!` operator returns the maximum of the operands.

~~~ stone
2 <! 3
#= Number.Integer(2)

2 >! 6 >! 1
#= Number.Integer(6)
~~~


### Boolean Operators

The simplest operation we can perform is Boolean negation (usually pronounced "not").
This is done using the `!` character as a unary prefix operator.
The `¬` (Unicode "not sign") may also be used.

~~~ stone
!TRUE
#= Boolean(Boolean.FALSE)

!FALSE
#= Boolean(Boolean.TRUE)

!!TRUE
#= Boolean(Boolean.TRUE)

!!FALSE
#= Boolean(Boolean.FALSE)

¬TRUE
#= Boolean(Boolean.FALSE)

¬FALSE
#= Boolean(Boolean.TRUE)

¬¬TRUE
#= Boolean(Boolean.TRUE)

!¬TRUE
#= Boolean(Boolean.TRUE)
~~~

We can also perform conjunction ("and") and disjunction ("or") operations on Booleans.
You can use the Unicode `∧` and `∨` symbols:

~~~ stone
TRUE ∧ FALSE
#= Boolean(Boolean.FALSE)

TRUE ∨ FALSE
#= Boolean(Boolean.TRUE)

(4 > 2) ∧ (6 <= 3)
#= Boolean(Boolean.FALSE)
~~~

Or you can use `+` for "or" and `*` (or `×` or `·`) for "and".
(These make sense if you think of `TRUE` as a `1` and `FALSE` as a `0`.)

~~~ stone
TRUE * FALSE
#= Boolean(Boolean.FALSE)

TRUE + FALSE
#= Boolean(Boolean.TRUE)

(4 > 2) × (6 <= 3)
#= Boolean(Boolean.FALSE)
~~~

Note that these operators do *not* short-cut; operations always evaluate all of their operands.


### Text Operators

We can use the `++` operator to concatenate strings.

~~~ stone
"abc" ++ "def"
#= Text("abcdef")


"abc" ++ "def" ++ "ghi"
#= Text("abcdefghi")
~~~
