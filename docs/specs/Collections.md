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
