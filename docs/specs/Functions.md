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

min(1/2, 1)
#= Number.Rational(1, 2)

min(3/2, 1)
#= Number.Integer(1)

max(1, 2, 3, 4/3, 22/7)
#= Number.Rational(22, 7)

identity(1, 2)
#! ArityError: 'identity' expects 1 argument, got 2
~~~


Function Definition
-------------------

You can define your own functions.

~~~ stone
square := (x) => {
    x * x
}
square(4)
#= Number.Integer(16)

sum_of_squares := (x, y) => {
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
add := (x, y) => {
    x + y
}
apply := (f, x, y) => {
    f(x, y)
}
apply(add, 1, 2)
#= Number.Integer(3)
~~~

Functions can implement recursion.

~~~ stone
fib := (n) => {
    if(n < 2, { n }, { fib(n - 1) + fib(n - 2) })
}
fib(1)
#= Number.Integer(1)
fib(11)
#= Number.Integer(89)
~~~
