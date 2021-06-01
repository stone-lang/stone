Literals
========

When writing a program, we frequently have to specify literal values.
Literal values are values (numbers, text, etc.) that are specified within the program itself,
as opposed to values that are provided as input to the program, or computed by the program.


Boolean
-------

The simplest literal is a Boolean value.
A Boolean value is either true or false.
These are represented by `TRUE` and `FALSE` in all capital letters.
These are actually values defined on the `Boolean` class, but they're also exposed globally.

~~~ stone
TRUE
#= Boolean(Boolean.TRUE)

FALSE
#= Boolean(Boolean.FALSE)
~~~


Null
----

There's a special value in Stone that represents "no valid value", named `NULL`.
It's (the only thing) defined in the `Null` class, but is exposed globally.

~~~ stone
NULL
#= Null(Null.NULL)
~~~


Integers
--------

Integers are the simplest type of number that we can work with.
Integers include all positive and negative whole numbers, plus 0.
Integers do not contain fractional portions.

We normally specify integers in decimal format:

~~~ stone
123
#= Number.Integer(123)
~~~

We can specify negative numbers, by prefixing with the `-` character.
We can also include an optional `+` prefix.
Leading zeros are allowed.
Underscores are allowed between digits to enhance readability.

NOTE: The `-` and `+` prefixes are part of the integer literal; there is no unary `-` or `+` operator.

~~~ stone
-123
#= Number.Integer(-123)

+123
#= Number.Integer(123)

00123
#= Number.Integer(123)

0
#= Number.Integer(0)

00000
#= Number.Integer(0)

-0
#= Number.Integer(0)

+0
#= Number.Integer(0)

1_000_000
#= Number.Integer(1000000)
~~~

Stone allows arbitrarily large numbers. The only limits are memory and computation time.
TODO: Arbitrary-precision numbers are not yet fully implemented; add specs when they are.


### Binary, Octal, and Hexadecimal Integers

Integers may also be expressed in binary, octal, or hexadecimal.
These are prefixed with `0b`, `0o`, and `0x`, respectively.
Like decimals, underscores are allowed between digits.

~~~ stone
0b10011001
#= Number.Integer(153)

-0b0000
#= Number.Integer(0)

0b00000000_00000001_11110110_00000000
#= Number.Integer(128512)

0o644
#= Number.Integer(420)

-0o1234567
#= Number.Integer(-342391)

0o11_644
#= Number.Integer(5028)

0xDEADBEEF
#= Number.Integer(3735928559)

0xDEAD_BEEF
#= Number.Integer(3735928559)

-0xface
#= Number.Integer(-64206)
~~~


Decimals
--------

Like most languages, Stone supports floating-point numbers.
These are called Decimals in Stone.
A Decimal has 1 or more digits before the decimal point, and 1 or more digits after.

Decimals may be expressed in scientific notation, using `e` or `E`.

There's a subtle difference from most languages, though.
Decimals are stored internally in a decimal format, instead of a binary format.
This means that every number you can write in decimal format will be stored exactly.
This is not the case with decimals stored in binary format.
The reason we do this is so that you won't run into unexpected results.
For example, in many languages `0.1 + 0.2 == 0.3` will return `FALSE`.
We prefer to give the correct answer in those situations, even if it's slower.
We plan to eventually support IEEE-754 floating-point numbers, for cases where speed
is more important, and when you prefer to take care of the rounding issues manually.

~~~ stone
1.0
#= Number.Decimal(+1.0E0)

1.00
#= Number.Decimal(+1.00E0)

0.0
#= Number.Decimal(0.0E0)

0.000
#= Number.Decimal(0.000E0)

0.1
#= Number.Decimal(+0.1E0)

0.10
#= Number.Decimal(+0.10E0)

-2.0E-1
#= Number.Decimal(-2.0E-1)

-2.00e-1
#= Number.Decimal(-2.00E-1)

-0.004
#= Number.Decimal(-0.004E0)

+5.0e+1
#= Number.Decimal(+5.0E+1)

1.0E+3
#= Number.Decimal(+1.0E+3)

1.000E+2
#= Number.Decimal(+1.000E+2)

100.0E0
#= Number.Decimal(+1.000E+2)

0.1 + 0.2
#= Number.Decimal(+0.3E0)

0.1 + 0.2 == 0.3
#= Boolean(Boolean.TRUE)
~~~


Rational Numbers
----------------

Stone is relatively unique in supporting rational literals.
(Ruby supports them, but requires that they be suffixed with an `r`.)
These are more commonly referred to as fractions.
Rationals consist of an integer followed by a slash (`/`) followed by an unsigned positive integer.
Rationals will be reduced to their simplest form.

~~~ stone
1/3
#= Number.Rational(1, 3)

-2/3
#= Number.Rational(-2, 3)

+1/3
#= Number.Rational(1, 3)

2/4
#= Number.Rational(1, 2)

0/5
#= Number.Rational(0, 1)

4/2
#= Number.Rational(2, 1)

1/0
#! DivisionByZero: invalid rational literal
~~~

Note that no whitespace is allowed before or after the slash within a rational literal.
If you put spaces around the slash, you'll be performing a division.
Division of integers will result in a rational result, but the extra computation is unnecessary.


Text
----

Stone can represent text (what most languages call "strings").
Text is enclosed in double quotes:

~~~ stone
"abc"
#= Text("abc")

""
#= Text("")

"#10 Downing Street"
#= Text("#10 Downing Street")

"We do block comments #[ like this ]#"
#= Text("We do block comments #[ like this ]#")
~~~

NOTE: There is no escaping or interpolation of any kind for text literals.
The `Text` class has methods to support those features.
TODO: Show ways to include a double-quote character:
    "${quote}".interpolate(quote: Text.Character.QUOTATION_MARK)
    "\u0022".escape
    "&quot;".html_entities
