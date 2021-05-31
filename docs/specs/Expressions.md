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

There are only a few exceptions to the mixed operators rule.
Addition and subtraction can be mixed, and have the same precedence.
Multiplication and division can be mixed, and have the same precedence.
The equality and comparison operators can be mixed with anything else, and have a lower precedence.

~~~ stone
1 + 2 - 3
#= Number.Integer(0)

1 - 2 + 3 - 4
#= Number.Integer(-2)

4 * 3 / -6
#= Number.Integer(-2)

1 < 2 <= 3
#= Boolean(Boolean.TRUE)

3 >= 4 > 3
#= Boolean(Boolean.FALSE)

0.1 + 0.2 == 0.3
#= Boolean(Boolean.TRUE)

0.1 + 0.1 < 0.3
#= Boolean(Boolean.TRUE)

0.3 > 0.1 + 0.1
#= Boolean(Boolean.TRUE)
~~~


### Equality Operators

Stone has the normal infix operators that you'd expect for equality and inequality.

~~~ stone
TRUE == TRUE
#= Boolean(Boolean.TRUE)

TRUE != FALSE
#= Boolean(Boolean.TRUE)

NULL != NULL
#= Boolean(Boolean.FALSE)

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

1/2 == 2/4
#= Boolean(Boolean.TRUE)

2/1 == 2
#= Boolean(Boolean.TRUE)

1.0 == 1.00
#= Boolean(Boolean.TRUE)

1.0 == 1
#= Boolean(Boolean.TRUE)

1/2 == 0.5
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

1/2 < 2/3
#= Boolean(Boolean.TRUE)

1 >= 1/2
#= Boolean(Boolean.TRUE)

1.01 > 1.000
#= Boolean(Boolean.TRUE)

1.0 > 1.000
#= Boolean(Boolean.FALSE)

1.0 < 1.000
#= Boolean(Boolean.FALSE)

1 < 1.0
#= Boolean(Boolean.FALSE)

1 > 1.0
#= Boolean(Boolean.FALSE)

1 >= 1.0
#= Boolean(Boolean.TRUE)

1.01 > 1
#= Boolean(Boolean.TRUE)

1/2 >= 0.5
#= Boolean(Boolean.TRUE)

1/2 >= 0.51
#= Boolean(Boolean.FALSE)

"abc" <= "abc"
#= Boolean(Boolean.TRUE)

"abc" <= "abcd"
#= Boolean(Boolean.TRUE)

TRUE > FALSE
#= Boolean(Boolean.TRUE)

1 < 2 < 3
#= Boolean(Boolean.TRUE)

3 >= 3 >= 2
#= Boolean(Boolean.TRUE)
~~~


### Numeric Operators

Stone has the normal infix numeric operators that you'd expect for addition, subtraction, and multiplication.
Stone has division, too, but it's a little different — it returns a Rational result.

~~~ stone
1 + 2
#= Number.Integer(3)

1 - 2
#= Number.Integer(-1)

2 * 3
#= Number.Integer(6)

2 / 3
#= Number.Rational(2, 3)

2 / -3
#= Number.Rational(-2, 3)

12 ÷ 4
#= Number.Integer(3)

60 ÷ 5 / 2
#= Number.Integer(6)

1/2 + 1/3
#= Number.Rational(5, 6)

1/2 - 1/3
#= Number.Rational(1, 6)

1/2 * 1/3
#= Number.Rational(1, 6)

1/2 / 1/3
#= Number.Rational(3, 2)

1 + 1/3
#= Number.Rational(4, 3)

2 - 1/2
#= Number.Rational(3, 2)

2 * 1/3
#= Number.Rational(2, 3)

3 * 1/3
#= Number.Integer(1)

1/3 / 2
#= Number.Rational(1, 6)

3 / 1/3
#= Number.Integer(9)

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

1/2 <! 1/3
#= Number.Rational(1, 3)

3/2 >! 1
#= Number.Rational(3, 2)
~~~


### Boolean Operations

The simplest operation we can perform is Boolean negation (usually pronounced "not").
This is done using the `¬` function.
That's the Unicode "not sign".
If your IDE or text editor does not make that easy for you,
the `!` function is an alias.

~~~ stone
¬(TRUE)
#= Boolean(Boolean.FALSE)

¬(FALSE)
#= Boolean(Boolean.TRUE)

¬(¬(TRUE))
#= Boolean(Boolean.TRUE)

¬(¬(FALSE))
#= Boolean(Boolean.FALSE)

!(TRUE)
#= Boolean(Boolean.FALSE)

!(FALSE)
#= Boolean(Boolean.TRUE)

!(!(TRUE))
#= Boolean(Boolean.TRUE)

!(¬(TRUE))
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
