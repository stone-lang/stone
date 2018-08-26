Expressions
===========

When writing a program, we often use expressions of various kinds to compute values.


Operators
---------

### Boolean Operators

The simplest operation we can perform is Boolean negation (usually pronounced "not").
This is done using the `!` character as a [unary](#unary) [prefix](#prefix) operator:

~~~ stone
!TRUE
#= Boolean(Boolean.FALSE)
~~~

~~~ stone
!FALSE
#= Boolean(Boolean.TRUE)
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


----

<dl>
  <dt id="unary">unary</dt> <dd>an operation taking 1 operand</dd>
  <dt id="prefix">prefix</dt> <dd>an operator that comes *before* its operand</dd>
  <dt id="operand">operand</dt> <dd>something that an operation operates on</dd>
</dl>
