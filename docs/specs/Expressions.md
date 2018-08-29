Expressions
===========

When writing a program, we often use expressions of various kinds to compute values.


Operators
---------

### Numeric Operators

Stone has the normal [infix](#infix) numeric operators that you'd expect
for addition, subtraction, and multiplication.
Note that Stone *requires* whitespace around infix operators.

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

Operators may be repeated:

~~~ stone
1 + 2 + 3
#= Number.Integer(6)
~~~

~~~ stone
2 * 3 * 4
#= Number.Integer(24)
~~~

However, operators may *not* be mixed, without using parentheses:

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


### Boolean Operators

The simplest operation we can perform is Boolean negation (usually pronounced "not").
This is done using the `!` character as a [unary](#unary) [prefix](#prefix) operator.

Note that white space is *not* allowed between the operator and the [operand](#operand).

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


----

<dl>
  <dt id="infix">prefix</dt> <dd>an operator that comes *between* its operand</dd>
  <dt id="unary">unary</dt> <dd>an operation taking 1 operand</dd>
  <dt id="prefix">prefix</dt> <dd>an operator that comes *before* its operand</dd>
  <dt id="operand">operand</dt> <dd>something that an operation operates on</dd>
</dl>
