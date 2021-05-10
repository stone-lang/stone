Functions
=========

Functions are procedures that take 1 or more arguments and return a result.


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

max(List(1, 2, 3, 4/3, 22/7))
#= Number.Rational(22, 7)

identity(1, 2)
#! ArityError: 'identity' expects 1 argument, got 2
~~~


Function Application
--------------------

Alternatively, you can use the function application (pipe) operators.

Note that this syntax only allows passing a single argument to a function.

~~~ stone
4 |> identity
#= Number.Integer(4)

TRUE |> identity
#= Boolean(Boolean.TRUE)

identity <| 4
#= Number.Integer(4)

identity <| TRUE
#= Boolean(Boolean.TRUE)

List(1, 2, 3, 4) |> identity |> max
#= Number.Integer(4)

max <| identity <| List(1, 2, 3, 4)
#= Number.Integer(4)
~~~


Function Definition
-------------------

You can define your own functions, using the lambda (`λ`) operator.
You may also use the "stabby lambda" syntax (`->`).
Your IDE or text editor should make it easy for you to type in the `λ` symbol ---
it might even change `->` to `λ` for you.

~~~ stone
square := λ(x) {
    x * x
}
square(4)
#= Number.Integer(16)

sum_of_squares := ->(x, y) {
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
add := λ(x, y) {
    x + y
}
apply := λ(f, x, y) {
    f(x, y)
}
apply(add, 1, 2)
#= Number.Integer(3)

apply(λ(x, y) { x + y }, 1, 2)
#= Number.Integer(3)
~~~

Functions can implement recursion.

~~~ stone
fib := λ(n) {
    if(n < 2, { n }, { fib(n - 1) + fib(n - 2) })
}
fib(1)
#= Number.Integer(1)
fib(11)
#= Number.Integer(89)
~~~


Anonymous Functions
-------------------

You don't actually have to give a function a name to use it.
You can just create it and call it directly.

~~~ stone
(λ(x) { x + 1 })(1)
#= Number.Integer(2)
~~~

You can pass an anonymous function as an argument to another function.

~~~ stone
#l := List(2, 3, 1)
#List.sort(λ(l, r) { l >= r })
##= List[Number.Integer](1, 2, 3)
~~~

You can have a function return an anonymous function.

~~~ stone
~~~
