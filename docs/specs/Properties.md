Properties
==========

Every expression in Stone has a _value_.
Anything that can be defined or stored in a variable is a _value_.
Every value in Stone has _properties_.
Each property has a name and its own associated value.
Values are immutable; the properties for a given value do not change; a `2` will never act like a `3`.

If a property for a value is unknown, it will return an error:

~~~ stone
a := 1
a.unknown_property
#! PropertyUnknownError: 'unknown_property' not recognized by Number.Integer
~~~

Properties are often meta-data: data about a piece of data. For example, the length of a List.

Sometimes properties are sub-components of the value.
For example, a List has properties to tell you its `first` and `last` member elements.

~~~ stone
l := List(1, 2, 3)
l.length  # NOTE: This will return a Number.Cardinal (a subclass of Number.Integer) in the future.
#= Number.Integer(3)
l.first
#= Number.Integer(1)
l.last
#= Number.Integer(3)
~~~
