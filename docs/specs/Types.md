Types
=====

Every value in Stone has an associated type.

You can get the type of a value by accessing its `type` property.

TODO: Any expression should allow a property access.

~~~ stone
a := 123
a.type
#= Number.Integer

b := "abc"
b.type
#= Text

TRUE.type
#= Boolean

NULL.type
#= Null

c := 1.0
c.type
#= Number.Decimal

d := 1/2
d.type
#= Number.Rational

f := λ(x) { 2 * x }
f.type
#= Function

l := List(1, 2, 3)
l.type
#= List[Number.Integer]
~~~
