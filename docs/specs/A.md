Chained Properties
==================

You can get the property of a property.

~~~ stone
l := List(1, 2, 3)
l.length.type
#= Type(Number.Integer)
~~~

Methods
-------

A method is a property that can be called as a function.

~~~ stone
t := "hello"
t.includes?("he")
#= Boolean(Boolean.TRUE)
~~~

Type Definitions
----------------

The type of a constant or variable is defined using `::`.
The name is on the left, preceded only by whitespace.
This allows us to see all the names (within a scope) very easily.
The type is to the right of the `::`.

~~~ stone
PI :: Measurement::Turn
~~~

The value of a constant is defined using `:=`.
Again, the name is on the left, for quick easy visibility.
The value to be assigned is on the right.

~~~ stone
PI := Measurement::Turn(1/2)
~~~

We can combine these into a single statement, like so:

~~~ stone
PI :: Measurement::Turn
   := Measurement::Turn(1/2)
~~~

By convention, the `::` and `:=` are aligned.

A function (or method) type definition is a little more complicated,
as we need to define the types of the _formal parameters_,
as well as the _return type_.
The parameters are listed within parentheses `()`.
Each parameter is itself a type definition.
Multiple parameters are separated by `,`
followed by whitespace (conventionally a space, in most cases).
The result type of a function comes after a `=>` (with whitespace).

TODO: Use an example that's a function, instead of a method.
TODO: Use an example that allows named or positional argument.

~~~ stone
nth :: (n_ :: Number.Ordinal) => elementType | Sequence.OutOfBounds
~~~

Arguments
---------

When calling a function (or any other callable),
we pass _arguments_ that take the place of the _formal parameters_.
(We'll abbreviate that to just _parameter_ in most cases.)
TODO: Clarify the terms, using verbiage from text books.

Arguments can be passed by name or position.

Usually, we just pass arguments by position.
That is, we just pass the value within the parentheses.

~~~ stone
collection.nth(1)
~~~

But sometimes we want to provide the parameter/argument names to add clarity:
TODO: Good examples

~~~ stone
map.get(key: "abc")
~~~

If the formal parameter name starts with an underscore (`_`),
then this is the **only** way to pass such an argument.

If the formal parameter name does **not** start with an underscore (`_`),
then we can pass the argument by name or position.

So if the definition of `nth` for `collection` is as follows:

~~~ stone
nth :: (n_ :: Number.Ordinal) => elementType | Sequence.OutOfBounds
~~~

then we **cannot** call it with parameter name:

~~~ stone
collection.nth(_n = 1) #! Error!!! TODO: What kind of error? Probably something like `Argument.Error`.
~~~

TODO: Show the named example first? Show it called by name and by position.

TODO: Details on how positional and named arguments interact.
