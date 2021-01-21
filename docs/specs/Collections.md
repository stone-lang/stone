Collections
===========

When writing a program, we frequently want to work with multiple values at the same time.
A Collection is a set of values gathered together, that can be treated as a single value.
The individual elements of a Collection can be easily iterated through as well.


List
----

The simplest collection is a List.
As the name suggests, a List is an ordered set of items.
A List has a type specifier, which specifies the types of values within the List.
If the values in the List are all of different types, the type specifier will by Any.
You won't normally need to explicitly include the type specifier, but you'll see it in output.

~~~ stone
List()
#= List[Any]()

List(1, 2, 3)
#= List[Number.Integer](Number.Integer(1), Number.Integer(2), Number.Integer(3))

List(1, 1 + 1, 1 + 1 + 1)
#= List[Number.Integer](Number.Integer(1), Number.Integer(2), Number.Integer(3))

List(1, "abc", FALSE)
#= List[Any](Number.Integer(1), Text("abc"), Boolean(Boolean.FALSE))
~~~


### List Properties

You can query a List for several properties, including the size/length of the list,
and whether it is empty.

~~~ stone
list := List(1, 2, 3)
empty := List()

list.length
#= Number.Integer(3)

list.size
#= Number.Integer(3)

list.empty?
#= Boolean(Boolean.FALSE)

empty.length
#= Number.Integer(0)

empty.size
#= Number.Integer(0)

empty.empty?
#= Boolean(Boolean.TRUE)
~~~

A List also has properties to access the first and last items,
as well as a List containing all but the first item.

~~~ stone
list := List(1, 2, 3)

list.first
#= Number.Integer(1)

list.head
#= Number.Integer(1)

list.last
#= Number.Integer(3)

list.rest
#= List[Number.Integer](Number.Integer(2), Number.Integer(3))

list.tail
#= List[Number.Integer](Number.Integer(2), Number.Integer(3))
~~~


### List Methods

You can determine whether a list contains a specific item.

~~~ stone
list := List(1, 2, 3)
empty := List()

list.includes?(1)
#= Boolean(Boolean.TRUE)

list.includes?(9)
#= Boolean(Boolean.FALSE)

empty.includes?(1)
#= Boolean(Boolean.FALSE)
~~~


### List Iteration

You'll often want to perform an operation on every item in a List.
The `map` method allows you to do this. (You may prefer to use its alias, `each`.)
It takes a function that takes 1 argument.

~~~ stone
list := List(1, 2, 3)
square := (x) => { x * x }

list.map((x) => { 2 * x })
#= List[Number.Integer](Number.Integer(2), Number.Integer(4), Number.Integer(6))

list.map(square)
#= List[Number.Integer](Number.Integer(1), Number.Integer(4), Number.Integer(9))

list.each(square)
#= List[Number.Integer](Number.Integer(1), Number.Integer(4), Number.Integer(9))

list.each((x, y) => { x + y })
#! ArityError: 'each' argument 'function' must take 1 argument

list.map(123)
#! TypeError: 'map' argument 'function' must have type Function[Any](Any)
~~~


### List Reduction

Sometimes you'll need to combine the items in a List to a single item.
You can do this using the `reduce` or `fold` methods.
(The `fold` method has aliases named `inject` and `foldl`.)
The `reduce` method takes the first 2 elements of the List, and applies the function to them.
It then applies the function to the previous result and each successive element.
The `fold` method is similar, but starts with a separately-specified initial value.
These functions take a function that takes 2 arguments.

~~~ stone
list := List(1, 2, 3, 4)
add := (x, y) => { x + y }
sub := (x, y) => { x - y }
square := (x) => { x * x }

list.reduce(add)
#= Number.Integer(10)

list.reduce((x, y) => { x * y })
#= Number.Integer(24)

list.fold(add, 1)
#= Number.Integer(11)

list.fold((x, y) => { x * y }, 1)
#= Number.Integer(24)

list.foldl(sub, 0)
#= Number.Integer(-10)

list.foldr(sub, 0)
#= Number.Integer(-2)

list.fold(square)
#! ArityError: 'fold' expects 2 arguments, got 1

list.fold(square, 1)
#! ArityError: 'fold' argument 'function' must take 2 arguments

list.reduce(123)
#! TypeError: 'reduce' argument 'function' must have type Function[Any](Any)
~~~
