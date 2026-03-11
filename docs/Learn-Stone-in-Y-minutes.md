# Learn Stone in Y Minutes

```stone
# Comments start with `#` and extend to the end of the line.

# NOT YET IMPLEMENTED: Line continuation with backslash (`\`) at beginning or end of line.
# "This is a long line" \
#     "that continues here."

# Stone has no keywords. The basic elements are literals, functions,
# blocks, definitions, function calls, properties, operators, and types.


### Literals

## Null
# The `Null` type has a single value, `NULL`. It represents a **lack** of a "regular" value.
NULL

## Boolean
# The `Boolean` type has 2 values, `TRUE` and `FALSE`.
TRUE
FALSE

## Integer
# The primary numeric type is the 64-bit signed integer, named `Int`.
123
+345
-456
0xDEADBEEF       # hexadecimal
0o755             # octal
0b01100110        # binary

## Decimal
# NOT YET IMPLEMENTED: Decimal literals.
# 1.0
# 3.14
# +2.27e12
# -12.3

## String
"String literals are enclosed in double quotes."
""                # empty string
"hello λ world"   # Unicode is supported

# Strings have no implicit escapes or interpolation.
"Backslash (\) and dollar ($) are literal characters."

# NOT YET IMPLEMENTED: Backslash escapes via the `escaped` property.
# "This string will have a tab\t and a newline\n".escaped

# NOT YET IMPLEMENTED: String interpolation via the `interpolated` method.
# "${name} is ${age} years old".interpolated(person)

# NOT YET IMPLEMENTED: String concatenation with the `++` operator.
# name := "Craig"
# greeting := "Hello, " ++ name


### Constants (Definitions)

# Constants are defined with `:=` and are immutable.
answer := 42
greeting := "Hello"

# Stone has a few built-in constants:
ZERO    # => 0
ONE     # => 1


### Built-in Functions

# `sum` adds two integers.
sum(5, 3)                # => 8
sum(-5, 3)               # => -2

# `if` takes a condition and two blocks (then and else).
if(TRUE, { 42 }, { 0 })          # => 42
if(FALSE, { 42 }, { 0 })         # => 0
if(==(5, 5), { 42 }, { 0 })      # => 42

# `if` can be nested.
if(TRUE, { if(FALSE, { 1 }, { 2 }) }, { 3 })  # => 2


### Operators

## Comparison Operators
# Comparison operators can be used in prefix (function) form or infix form.
# Infix form requires whitespace around the operator.
==(5, 5)    # prefix form # => TRUE
5 == 5      # infix form  # => TRUE
5 != 3      # => TRUE
3 < 5       # => TRUE
5 <= 5      # => TRUE
5 > 3       # => TRUE
5 >= 5      # => TRUE

# Unicode alternatives are supported/encouraged.
5 ≠ 3       # same as !=
3 ≤ 5       # same as <=
5 ≥ 3       # same as >=

## Boolean Operators
# AND - function form and Unicode infix form.
and(TRUE, FALSE)      # => FALSE
TRUE ∧ FALSE          # => FALSE
TRUE ∧ TRUE ∧ TRUE    # chainable # => TRUE

# OR
or(TRUE, FALSE)       # => TRUE
TRUE ∨ FALSE          # => TRUE
FALSE ∨ FALSE ∨ TRUE  # chainable # => TRUE

# NOT - function form, Unicode form, and property form.
not(TRUE)             # => FALSE
¬(TRUE)               # => FALSE
TRUE.not              # => FALSE

# XOR
xor(TRUE, FALSE)      # => TRUE
TRUE ⊻ FALSE          # => TRUE

# Mixing different boolean operators requires parentheses.
(TRUE ∧ FALSE) ∨ TRUE          # => TRUE
# TRUE ∧ FALSE ∨ TRUE          # Error! Must use parentheses.

## Arithmetic Operators
# NOT YET IMPLEMENTED: Arithmetic operators beyond `sum`.
# 2 + 3         # => 5
# 10 - 4        # => 6
# 2 * x + y     # => ...

## Equality
# `==` and `!=` work across all types.
42 == 42              # => TRUE
"hi" == "hi"          # => TRUE
NULL == NULL          # => TRUE
# Cross-type comparisons are always FALSE.
42 == "42"            # => FALSE


### Blocks

# Blocks are enclosed in `{}` and act as zero-parameter lambdas.
result := { 42 }
result()              # => 42

# Blocks create a new scope; inner definitions don't leak out.
x := 1
{ x := 2 }           # x is 2 inside the block only
x                     # => 1 (outer scope is unchanged)


### Lambdas (Anonymous Functions)

# Create anonymous functions with the lambda operator `λ`.
λ(x) { sum(x, x) }

# Assign lambdas to constants to create named functions.
double := λ(x) { sum(x, x) }
double(21)            # => 42

# Multiple parameters.
add := λ(x, y) { sum(x, y) }
add(3, 4)             # => 7

# Multiple statements; the last expression is the return value.
compute := λ(x) {
    temp := sum(x, x)
    sum(temp, ONE)
}
compute(20)           # => 41

# Lambdas capture outer scope (closures).
addend := 21
f := λ(x) { sum(x, addend) }
f(21)                 # => 42

# Parameters shadow outer variables.
x := 100
g := λ(x) { x }
g(5)                  # => 5


### Properties

## Built-in Properties

# Integer properties:
42.positive?          # => TRUE
42.negative?          # => FALSE
0.zero?               # => TRUE

# Boolean property:
TRUE.not              # => FALSE

# String property:
"hello".byte_count    # => 5
"λ".byte_count        # => 2 (byte count, not character count)

# Properties can be chained.
42.positive?.not.not  # => TRUE

## Computed Properties

# Define custom properties on types with `Type@property`.
Int@double := λ(this) { sum(this, this) }
21.double             # => 42

Int@abs := λ(this) { if(this.negative?, { sum(0, sum(0, this).negative? ... }, { this }) }
# (The actual abs implementation uses LLVM intrinsics.)

# Computed properties work on any type.
Bool@yes? := λ(this) { this }
TRUE.yes?             # => TRUE


### Records (Structured Data)

# Records are immutable value objects with named, typed fields.
Point := Record(x :: Int, y :: Int)
Person := Record(name :: String, age :: Int)

# Instantiate by passing field values in order.
pt := Point(10, 20)
p := Person("Craig", 54)

# Access fields as properties.
pt.x                  # => 10
pt.y                  # => 20
p.name                # => "Craig"

# Records use structural equality.
Point(10, 20) == Point(10, 20)   # => TRUE
Point(10, 20) == Point(15, 25)   # => FALSE

# Records are immutable. They're "value objects".
# pt.x = 1              # compilation error!

# A method is just a function bound to a property.
# o.m(x)                # roughly de-sugars to Type.of(o)@m(o, x)

# Computed properties on records.
Point@sum := λ(this) { sum(this.x, this.y) }
Point(10, 20).sum     # => 30

# NOT YET IMPLEMENTED: Record subclassing.
# SubClass := ParentClass.subclass(additional_field :: SomeType)


### Recursive Data Structures

# Records can reference their own type. Use NULL as a terminator.
IntList := Record(first :: Int, rest :: IntList)

list := IntList(1, IntList(2, IntList(3, NULL)))
list.first             # => 1
list.rest.first        # => 2
list.rest.rest.first   # => 3
list.rest.rest.rest == NULL  # => TRUE

# Trees work the same way.
Tree := Record(value :: Int, left :: Tree, right :: Tree)
leaf := Tree(1, NULL, NULL)
tree := Tree(2, leaf, Tree(3, NULL, NULL))
tree.left.value        # => 1


### Types

# By convention, type identifiers use PascalCase.

## Type Annotations
# Declare types with `::`.
x :: Int
x := 42

double :: (Int) -> Int
double := λ(x) { sum(x, x) }

# Function types use `->` syntax.
# () -> Int                   # zero parameters
# (Int) -> Int                # one parameter
# (Int, Int) -> Int           # two parameters
# (Int) -> ((Int) -> Int)     # function returning a function

## Type Introspection

# `Type.of()` returns the type of any value.
Type.of(42).as_String          # => "Int"
Type.of(TRUE).as_String        # => "Bool"
Type.of("hello").as_String     # => "String"
Type.of(NULL).as_String        # => "Null"

# Type properties:
Type.of(42).primitive?         # => TRUE
Type.of(42).record?            # => FALSE
Type.of(42).size               # => 8 (bytes)

# Record type introspection:
Point := Record(x :: Int, y :: Int)
Type.of(Point(1, 2)).record?              # => TRUE
Type.of(Point(1, 2)).fields.first.name    # => "x"
Type.of(Point(1, 2)).fields.first.type.as_String  # => "Int"

# Type equality:
Type.of(42) == Type.of(1)      # => TRUE (both Int)
Type.of(42) == Type.of(TRUE)   # => FALSE


### Union Types

# Union types combine multiple types with `|`.
# Used in type annotations and record fields.
Box := Record(value :: Int | Null)
b1 := Box(42)
b2 := Box(NULL)
b1.value               # => 42
b2.value               # => nil

# Multi-alternative unions:
# x :: Int | String | Bool

# Type.of() returns the actual variant type.
Type.of(b1.value).as_String    # => "Int"
Type.of(b2.value).as_String    # => "Null"


### Sum Types (Algebraic Data Types)

# Sum types use `|` at the expression level.
IntOption := Null | Record(value :: Int)

## Generic Sum Types
Option :: (Type) -> Type
Option := λ(T) { Null | Record(value :: T) }

IntOption := Option(Int)
some := IntOption(42)
some.value             # => 42

## Recursive Sum Types (Lists)
List :: (Type) -> Type
List := λ(T) { Null | Record(first :: T, rest :: List(T)) }

IntList := List(Int)
list := IntList(1, IntList(2, IntList(3, NULL)))
list.first             # => 1
list.rest.first        # => 2
list == NULL           # => FALSE
list.rest.rest.rest == NULL  # => TRUE


### Generic Types

# Generic types are type-level lambdas.
Box :: (Type) -> Type
Box := λ(T) { Record(value :: T) }

IntBox := Box(Int)
StringBox := Box(String)

b := IntBox(42)
b.value                # => 42
s := StringBox("hello")
s.value                # => "hello"

# Multiple type parameters.
Pair :: (Type, Type) -> Type
Pair := λ(K, V) { Record(key :: K, value :: V) }
IntString := Pair(Int, String)
p := IntString(42, "answer")
p.key                  # => 42
p.value                # => "answer"

# Composed generics.
Maybe :: (Type) -> Type
Maybe := λ(T) { Record(value :: T, present :: Bool) }
ListOfMaybe := List(Maybe(Int))


### Collections
# NOT YET IMPLEMENTED: Built-in collection types (List, Map, Set, etc.).
```
