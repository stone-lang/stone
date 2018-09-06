Functions
=========


Function Call
-------------

You can call a function by name, using syntax that's pretty familiar.
There are a few built-in functions.

~~~ stone
identity(4)
#= Number.Integer(4)

identity(TRUE)
#= Boolean(Boolean.TRUE)

identity("abc")
#= Text("abc")

min(1, 2)
#= Number.Integer(1)

max(1, 2, 3)
#= Number.Integer(3)
~~~


Function Definition
-------------------

You can define your own functions.

~~~ stone
square(x) := function {
    x * x
}
square(4)
#= Number.Integer(16)
~~~
