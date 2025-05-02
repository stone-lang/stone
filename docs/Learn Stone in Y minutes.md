Learn Stone in Y minutes
========================

WARNING: Stone is a work in progress. Some of these things are not implemented yet, and some will change.

Syntax
------

* White space matters - you need space around almost all operators
    * So `1+1` is a syntax error; it needs to be `1 + 1`
* Line comments begin with a `#` and continue to the end of the line
* Block comments start with `#[` and end with `]#`
    * These CANNOT be nested
* Literals
    * Boolean - `TRUE` or `FALSE`
    * Null - `NULL`, represents "no valid value"
    * String - enclosed in double-quotes
    * Integer - arbitrary-precision
        * Decimal: `01234`, NO prefix (leading `0`s ignored)
        * Hex: `0x` prefix
        * Binary: `0b` prefix
        * Octal: `0o` prefix
    * Decimal - decimal-based arbitrary-precision floating point
        * You really only need to know that this allows `0.1 + 0.2 == 0.3` to work as you'd expect
            * This is not the case in most languages
    * Rational: fractions, with integer numerator and denominator, separated by `/` with no whitespace
        * Example: `1/3`
        * If you put spaces around the `/` it becomes a division operation
* Definitions have the name on the left, `:=`, then the value
    * Definitions are how you define a constant
        * Function and method names are constants
        * Class names are constants
    * Identifiers
        * there are NO reserved keywords
            * there are many pre-defined constants that _act_ much like keywords
        * consist of ANY character (letter, number, symbol) EXCEPT the following:
            * whitespace
            * control characters
            * unassigned Unicode characters
            * reserved characters
                * ``()[]{}«»#,.:;@^`"\``
        * MUST NOT start like a number (possibly preceded by a `+` or `-` sign)
* There's ALMOST no operator precedence
    * If you mix operators, you HAVE TO use parentheses
        * EXCEPTION: You CAN mix `+` and `-`
        * EXCEPTION: You CAN mix `×` and `÷` (AKA `*` and `/`)
        * EXCEPTION: Comparison operators have lower precedence: `0.1 + 0.1 < 0.3`
        * EXCEPTION: Early return operator (if I choose to implement it)
* Blocks indicate code that _might_ run later — possibly multiple times, with different data each time
* Operators can be "chained", so this works: `5 >= x >= 2`
    * It's treated as a single call to the operator, passing however many arguments are there are operands
* There is no unary `-` or `+` operator
    * But Integer and Decimal literals can begin with a `+` or `-`

Style
-----

* Definitions are listed in order of _importance_
    * The most important definition comes first in the source code
        * This will be the item that's exported from the source code file
    * Following definitions are used by the exported definition
    * This helps tell a story to help the reader understand the code better
* Predicate functions and methods (those that return a Boolean result) have names ending with a `?`
* It's preferred to use Unicode operators
    * Example: `×` is preferred over `*` for multiplication
    * IDEs and text editors should do this automatically

Types
-----

* The type system is relatively unobtrusive
    * You need type definitions for publicly-exposed functions/methods
    * You need type definitions for fields defined in a structure, class, or actor
    * You don't need to declare the types of local variables or anything else
* The builtin types are a little more detailed/extensive/hierarchical than most type systems

Standard Library
----------------

* Imports are done via definitions, just like any other class or function definition
    * Example: `MyClass := import("MyClass", Range(Version(1.2.3), Version(1.3), exclude_end: true))`
    * This means that every file has its own view of the world
        * What one file calls `A` might not be called `A` in a different file
* Method names are usually based on Ruby
* There's a standard _prelude_ that imports much of the standard library
    * You can easily override the prelude

Collections
-----------

* The basic data structures are List and Map
    * A List is an ordered set of items
    * List is known as array in most languages
    * Map is known in other languages as dictionary, hashmap, hash, or associative array
* Indexing (of lists and other sequences) is 1-based
    * Manually indexing a sequence is generally frowned upon
        * Because you should generally iterate through a sequence as a whole
    * If you want the 10th element of a list, you'd do `list.nth(10)`
    * There's `first`, an alias for `nth(1)`
    * There's also `rest`, for all but the first item
    * There's also `last`
