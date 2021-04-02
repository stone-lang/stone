Collections
===========

When writing a program, we frequently want to work with multiple values at the same time.
A Collection is a set of values gathered together, that can be treated as a single value.
The individual elements of a Collection can be easily iterated through as well.


List
----

The simplest collection is a _List_.
As the name suggests, a List is an ordered set of items.
A List has a type specifier, which specifies the types of values within the List.
If the values in the List are all of different types, the type specifier will by Any.
You won't normally need to explicitly include the type specifier, but you'll see it in output.

~~~ stone
List()
#= List[Any]()

List(1, 2, 3)
#= List[Number.Integer](1, 2, 3)

List(1, 1 + 1, 1 + 1 + 1)
#= List[Number.Integer](1, 2, 3)

List(1, "abc", FALSE)
#= List[Any](1, "abc", Boolean.FALSE)
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
#= List[Number.Integer](2, 3)

list.tail
#= List[Number.Integer](2, 3)
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
#= List[Number.Integer](2, 4, 6)

list.map(square)
#= List[Number.Integer](1, 4, 9)

list.each(square)
#= List[Number.Integer](1, 4, 9)

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


Pair
----

A _Pair_ is a data structure containing 2 items, related in some (programmer-determined) way.
The 2 items don't need to have the same type.
The 2 items can be thought of as (and referenced as):

* `first` and `second`
* `first` and `last`
* `left` and `right`
* `key` and `value`

If you need to specify the type of items in the Pair, you'll specify the type of each.

~~~ stone
Pair("a", 1)
#= Pair[Text, Number.Integer]("a", 1)

Pair(NULL, NULL)
#= Pair[Null, Null](Null.NULL, Null.NULL)

Pair()
#! ArityError: 'Pair' expects 2 arguments, got 0

Pair(1)
#! ArityError: 'Pair' expects 2 arguments, got 1

Pair(1, 2, 3)
#! ArityError: 'Pair' expects 2 arguments, got 3
~~~

### Pair Properties

You can query a Pair for several properties, including the 2 individual items:

~~~ stone
pair := Pair("a", 1)

pair.first
#= Text("a")

pair.second
#= Number.Integer(1)

pair.last
#= Number.Integer(1)

pair.key
#= Text("a")

pair.value
#= Number.Integer(1)

pair.left
#= Text("a")

pair.right
#= Number.Integer(1)
~~~

A Pair is not a Collection, nor is it a Sequence.
However, Pair plays a large role in the second-most important collection type — Map.


Map
---

A _Map_ is a data structure containing a "mapping" from keys to values.
Each _key_ may only map to a single _value_.
So a given key can only be in the map once; but values do *not* need to be unique.
In other programming languages, this data structure is often called an associative array, dictionary, hashmap, or hash.
A Map could also be considered a List of Pair elements, which is how it's constructed:

~~~ stone
Map(Pair("a", 1), Pair("b", 2), Pair("c", 3))
#= Map[Text, Number.Integer](Pair("a", 1), Pair("b", 2), Pair("c", 3))

Map()
#= Map[Any, Any]()
~~~

TODO: Test for unique keys.

### Map Properties

You can query a Map for several properties, including its list of keys and values,
its length/size, and whether it's empty.

~~~ stone
map := Map(Pair("a", 1), Pair("b", 2), Pair("c", 3))
empty := Map()

map.keys
#= List[Text]("a", "b", "c")

map.values
#= List[Number.Integer](1, 2, 3)

map.length
#= Number.Integer(3)

map.size
#= Number.Integer(3)

map.empty?
#= Boolean(Boolean.FALSE)

empty.length
#= Number.Integer(0)

empty.size
#= Number.Integer(0)

empty.empty?
#= Boolean(Boolean.TRUE)
~~~

### Map Methods

You can determine whether a Map contains a specific key, value, or pair.
You can get the value associated with a given key.

~~~ stone
map := Map(Pair("a", 1), Pair("b", 2), Pair("c", 3))

map.has_key?("c")
#= Boolean(Boolean.TRUE)

map.has_value?(1)
#= Boolean(Boolean.TRUE)

map.includes?(Pair("b", 2))
#= Boolean(Boolean.TRUE)

map.get("a")
#= Number.Integer(1)

map.get("c")
#= Number.Integer(3)
~~~
