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

identity(1, 2)
#! ArityError: 'identity' expects 1 argument, got 2
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

sum_of_squares(x, y) := function {
    xx := x * x
    yy := y * y
    xx + yy
}
sum_of_squares(3, 4)
#= Number.Integer(25)

square(3, 4)
#! ArityError: 'square' expects 1 argument, got 2

sum_of_squares(3)
#! ArityError: 'sum_of_squares' expects 2 arguments, got 1
~~~

Functions are first-class — you can pass a function to a function.

~~~ stone
add(x, y) := function {
    x + y
}
apply(f, x, y) := function {
    f(x, y)
}
apply(add, 1, 2)
#= Number.Integer(3)
~~~

Functions can implement recursion.

~~~ stone
fib(n) := function {
    if(n < 2, { n }, { fib(n - 1) + fib(n - 2) })
}
fib(1)
#= Number.Integer(1)
fib(11)
#= Number.Integer(89)
~~~
