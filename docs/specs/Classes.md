Classes
=======

Classes define the structure and behavior of objects.


Constructing a Class
--------------------

You can create a class just like you'd create anything else:
by calling a constructor function with the name of the type of thing you want:

TRYING OUT SOME IDEAS FOR SYNTAX
--------------------------------

Simplest thing that could possibly work: `Class` just takes 5 arguments, in a specific order.

* VERDICT: probably a decent place to start
* PRO: easy to implement
* CON: hard to extend
* CON: doesn't handle class methods, constants, etc.
* CON: pretty ugly
* CON: no way to use function definition sugar (`f(x) := { ... }`)

~~~ stone
C := Class("C", # name
    Object, # parent class
    List(Sequence.Finite, Collection.Ordered), # interfaces
    Map(
        # properties and their types
        a: Integer
    ),
    Map(
        # methods and their implementations
        square: (x) => { x * x },
        a_square: () => { @a * @a }
    )
)
~~~

Named arguments

* VERDICT: probably a decent place to start
* PRO: not too difficult to implement
    * just have to implement named arguments in the language
        * I want to implement that anyway
* PRO: easy enough to extend
* CON: pretty ugly
* CON: no way to use function definition sugar (`f(x) := { ... }`)

~~~ stone
C := Class(name = "C",
    parent = Object,
    interfaces = List(Sequence.Finite, Collection.Ordered),
    properties = Map(
        a: Integer
    ),
    methods = Map(
        square: (x) => { x * x },
        a_square: () => { @a * @a }
    )
)
~~~

Everything in the body, sigil for class attributes

* PRO: uses definition syntax
* CON: have to understand the difference between class properties and instance properties

~~~ stone
C := Class({
    # Class properties
    .name := "C"
    .parent := Object
    .interfaces := List(Sequence.Finite, Collection.Ordered)

    # Class methods
    .create(a) := { @a = a }

    # Instance properties (fields)
    a := Property(Integer)

    # Computed properties
    a_square := { @a * @a }

    # Instance methods
    square(x) := { x * x }
})
~~~

Hybrid named arguments and body

* PRO: class-level items are separated from instance-level items
* CONS: doesn't handle class methods

~~~ stone
C := Class(name = "C", parent = Object, interfaces = List(Sequence.Finite, Collection.Ordered),
{
    # Instance properties (fields)
    a := Property(Integer)

    # Computed properties
    a_square := { @a * @a }

    # Instance methods
    square(x) := { x * x }
})
~~~


Instantiating an Object
-----------------------

A _constructor_ is a function that creates an object of a given class.
Each class has a default constructor that has the same name as the class.
You'll usually use that to create an object.

~~~ stone
C := Class("C",
    Object,
    List(),
    Map(
        Pair("a", Integer)
    ),
    Map(
        Pair("square", (x) => { x * x }),
        #Pair("a_plus", (x) => { @a + x }),
    )
)
c := C(123)
#= C(Number.Integer(123))

C.type
#= Class(C)

C.a
#= Number.Integer(123)

C.square(2)
#= Number.Integer(4)
~~~
