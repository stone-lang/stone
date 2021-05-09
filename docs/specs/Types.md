Types
=====

Every value in Stone has an associated type.

You can use the built-in `type` function to get the type of a value.

~~~ stone
type(123)
#= Number.Integer

type("abc")
#= Text

type(TRUE)
#= Boolean

type(NULL)
#= Null

type(1.0)
#= Number.Decimal

type(1/2)
#= Number.Rational

f := λ(x) { 2 * x }
type(f)
#= Function
~~~
