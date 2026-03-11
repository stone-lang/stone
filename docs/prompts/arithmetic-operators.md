# Arithmetic Operators

## Overview

Implement arithmetic operators and functions for Stone.
These operators work on Int, but later we will extend them to other numeric types.
Each operator will desugar to a function call with the name equivalent to the operator (`+` desugars to `+`, `-` desugars to `-`, etc).
I've already checked that these are valid identifiers in LLVM IR.
The compiler should have the opportunity to inline the functions.
All operations check for overflow and return `Error.Overflow` when result exceeds Int64 range.

I'm not sure what to do about the "properties" of these operations (commutativity, associativity, identity element, etc).
I'd like to represent them in the language somehow, but I'm not sure how.
I don't see a way to do that well, given that it's a property of an **operation** _within_ a type.
Any help/ideas appreciated!
Maybe we could have some kind of metadata on the functions that would allow us to specify these "properties".
And it would be great if we could include the mathematical group concept too, as _its_ "properties" must be satisfied by the operations.

## Prerequisites

- **Union Types**: Required to return errors from arithmetic operations (e.g., `Int | Error.Overflow`)
    - See `docs/prompts/union-types.md`
    - Without union types, errors will halt/abort execution

## Design Decisions

The following decisions have been made for this implementation:

### Runtime Error Handling

**Decision**: Halt/abort with error message for now; return tagged unions (Result types) later.

- **Phase 1**: Errors halt execution with a clear error message (simplest approach)
- **Phase 2**: Once union types are implemented, return `Int | Error` tagged unions

This matches Stone's philosophy of explicit error handling while allowing incremental development.

### Mixed Operator Detection

**Decision**: Transform-time error (after parsing, before LLVM generation).

When mixing different arithmetic operators without parentheses (e.g., `2 + 3 × 4`),
the error is raised during the AST transformation phase. This provides clear error
messages with source location information.

### Unicode and ASCII Operators

**Decision**: Support both from the start.

All Unicode operators (`×`, `÷`, `−`) and their ASCII alternatives (`*`, `/`, `-`)
are supported simultaneously. This follows the existing pattern for comparison
operators (`≤`, `≥`, `≠` alongside `<=`, `>=`, `!=`).

### Operator vs Function Naming

**Decision**: Primitive functions use descriptive names; operators are Stone-level wrappers.

- `sum`, `difference`, `product`, `quotient`, `remainder`, `power` are defined as
  LLVM built-in functions using intrinsics
- `+`, `-`, `×`, `÷`, `^` are Stone-level functions that call the primitives
- This allows operators to be redefined for other types without changing the primitives

Example: `+(x, y) := { sum(x, y) }`

### Implementation Order (TDD)

1. Write tests first (specification)
2. Implement built-in functions (`sum`, `difference`, `product`, `quotient`, `remainder`, `power`)
3. Add operator aliases (`+` → `sum`, `-` → `difference`, etc.)
4. Add computed properties (`Int@abs`)
5. Add mixed operator detection

## Arithmetic Operators

### Addition: `+`

```stone
# Integer addition
2 + 3       # 5
-5 + 10     # 5
10 + -5     # 5
0 + 42      # 42
1 + 2 + 3   # 6

# Desugars to a function call (don't forget, we don't have a unary `+`, and the operators are valid identifiers):
+(2, 3)
+(-5, 10)
+(10, -5)
+(0, 42)
+(1, 2, 3) # if/once we have varargs support; otherwise `+(+(1, 2), 3)`

# The default definition is: 
+(x, y) := { sum(x, y) }  # varargs, if/once we have support for them
```

#### Implement `sum(a, b)`

**Implementation**: LLVM `sadd.with.overflow` intrinsic to detect overflow.

**Properties**:

- Commutative: `a + b == b + a`
- Associative: `(a + b) + c == a + (b + c)`
- Identity element: `0`

**Overflow**: returns an Error.Overflow when result exceeds Int64 range.

### Subtraction: `−` or `-`

Subtraction uses the Unicode minus sign (U+2212), or the ASCII "hyphen-minus".
I recommend that editors, formatters, and linters _normalize_ these to the **minus sign** (U+2212).
Counter-intuitively, I'm going to recommend that we keep the hyphen-minus as the default for negative literals.

```stone
# Integer subtraction
5 − 3       # 2
10 − -20    # 30
0 − 5       # -5
-5 − 10     # -15
1 − 2 − 3   # -4

# Desugars to a function call (don't forget, we don't have a unary `-`):
−(5, 3)
−(10, -20)
−(0, 5)
−(-5, 10)
−(1, 2, 3) # if/once we have varargs support; otherwise `−(−(1, 2), 3)`

# The default definition is:
−(x, y) := { difference(x, y) }  # varargs, if/once we have support for them
```

#### Implement `difference(a, b)`

**Implementation**: LLVM `ssub.with.overflow` intrinsic to detect overflow.

**Properties**:

- Not commutative: `a − b != b − a` (in general)
- Associative: `a − b − c == (a − b) − c`
- Identity element: `0` (right element only)

**Note**: Stone does not support negation (unary minus).
Use `0 − n` to negate a value.
Stone **does** have negative literals, e.g. `-5`.

### Multiplication: `×` or `*`

Multiplication uses the Unicode multiplication sign (U+00D7), or the ASCII asterisk `*`.
I recommend that editors, formatters, and linters _normalize_ these to the **multiplication sign** (U+00D7).

```stone
# Integer multiplication
3 × 4       # 12
-2 × 5      # -10
0 × 100     # 0
1 × -42     # -42

# ASCII alternative
3 * 4       # 12

# Desugars to a function call:
×(5, 3)
×(10, -20)
×(0, 5)
×(-5, 10)
×(1, 2, 3) # if/once we have varargs support; otherwise `×(×(1, 2), 3)`

# The default definition is:
×(x, y) := { product(x, y) }  # varargs, if/once we have support for them
```

#### Implement `product(a, b)`

**Implementation**: LLVM `smul.with.overflow` intrinsic to detect overflow.

**Properties**:

- Commutative: `a × b == b × a`
- Associative: `(a × b) × c == a × (b × c)`
- Identity element: `1`
- Zero element: `0` (anything times 0 is 0)

### Division: `÷` or `/`

Division uses the Unicode division sign (U+00F7), or the ASCII forward slash `/`.
I recommend that editors, formatters, and linters _normalize_ these to the **division sign** (U+00F7).

```stone
# Integer division (truncated toward zero)
10 ÷ 3      # 3
20 ÷ 4      # 5
-10 ÷ 3     # -3 (truncated toward zero)
10 ÷ -3     # -3

# ASCII alternative
10 / 3      # 3

# Division by zero - error
10 ÷ 0      # Error.DivisionByZero

# Desugars to a function call:
÷(10, 3)
÷(20, 4)
÷(-10, 3)
÷(10, -3)
÷(1, 2, 3) # if/once we have varargs support; otherwise `÷(÷(1, 2), 3)`

# The default definition is:
÷(x, y) := { quotient(x, y) }  # varargs, if/once we have support for them
```

#### Implement `quotient(a, b)`

**Implementation**: LLVM `sdiv` instruction (signed division) with explicit zero check.

**Properties**:

- Not commutative
- Division by zero returns an Error.DivisionByZero
- Integer division truncates toward zero

**Note**: Truncates toward zero, so `-10 ÷ 3 == -3`, not `-4`.

### Modulo: `remainder`

No operator for modulo/remainder.

#### Implement `remainder(a, b)`

**Implementation**: LLVM `srem` instruction (signed remainder) with explicit zero check.

**Properties**:

- Sign of result matches sign of dividend (left operand)
- `remainder(a, b)` has magnitude less than `|b|`
- Modulo by 0 returns an Error.DivisionByZero

### Exponentiation: `^`

```stone
# Exponentiation
-2 ^ 3      # -8
10 ^ 2      # 100
5 ^ 0       # 1
2 ^ 10      # 1024

# Negative exponent (error)
2 ^ -3      # Error.NegativeExponent (should return a FloatingPoint, once we have them)

# Desugars to a function call:
^(-2, 3)
^(20, 2)
^(5, 0)
^(2, 10)
^(1, 2, 3) # if/once we have varargs support; otherwise `^(^(1, 2), 3)`

# The default definition is:
^(x, y) := { power(x, y) }  # varargs, if/once we have support for them
```

#### Implement `power(a, b)`

**Implementation**:

- For small positive integer exponents: repeated multiplication with overflow checking
- For general case: binary exponentiation algorithm
- For negative exponents: Error.NegativeExponent (should return a FloatingPoint, once we have them)

**Properties**:

- Not commutative: `2 ^ 3 != 3 ^ 2`
- Not associative: `(2 ^ 3) ^ 2 != 2 ^ (3 ^ 2)`
- By convention: `a ^ 0 == 1` for all `a`

### Absolute Value

```stone
# Absolute value
abs(-42)        # 42
abs(42)         # 42

# As property of an Int
-42.abs         # 42 (desugars to `Int@abs(-42)`)
```

#### Implement `abs(a)` and `Int@abs`

**Implementation**:

```stone
abs := λ(x) { if(x.negative?, { 0 - x }, { x }) }
```

Or direct LLVM:

```llvm
%is_neg = icmp slt i64 %x, 0
%negated = sub i64 0, %x
%result = select i1 %is_neg, i64 %negated, i64 %x
```

**Overflow**: Special case for `min_int` - raises Error.Overflow

## Operator Precedence and Associativity

**No precedence between arithmetic operators** - parentheses are required when mixing operators:

```stone
2 + 3 × 4       # Error.MixedOperators: Use parentheses to explicitly group operations.

# Explicit grouping required
2 + (3 × 4)     # 14
(2 + 3) × 4     # 20

# Single operator is fine
1 + 2 + 3       # 6 (left-to-right)
2 × 3 × 4       # 24 (left-to-right)

# Once we have varargs, these will desugar to:
+(1, 2, 3)
×(2, 3, 4)

which will (by default) be evaluated left-to-right.
```

**Exception**: Relational (comparison) operators have lower precedence than arithmetic:

```stone
# Relational (comparison) operators bind less tightly, so both sides of the relation are evaluated first.
2 + 3 == 5 + 1      # (2 + 3) == (5 + 1) (OK, no ambiguity)
x × 3 > 2 × 5       # (x × 3) > (2 × 5)  (OK, no ambiguity)
```

All operators are left-associative when repeated:

```stone
10 - 5 - 2      # (10 - 5) - 2 = 3
100 ÷ 10 ÷ 2    # (100 ÷ 10) ÷ 2 = 5
2 ^ 3 ^ 2       # (2 ^ 3) ^ 2 = 64 (left-associative, unlike mathematical convention)
```

**Note**: Mathematical convention treats exponentiation as right-associative (`2^3^2 = 2^(3^2) = 512`), but Stone uses left-associativity for consistency.

## Overflow Behavior

All arithmetic operations check for overflow and raise runtime errors:

```stone
max_int := 9_223_372_036_854_775_807
max_int + 1                    # Error.Overflow: Int overflow

min_int := -9_223_372_036_854_775_808
min_int - 1                    # Error.Overflow: Int underflow

1_000_000_000 × 1_000_000_000  # Error.Overflow: Int overflow
```

**Rationale**: Overflow errors prevent silent bugs.
Wrapping behavior (two's complement) can lead to subtle correctness issues.

**Implementation**: Use LLVM's `with.overflow` intrinsics:

- `llvm.sadd.with.overflow` - signed addition with overflow flag
- `llvm.ssub.with.overflow` - signed subtraction with overflow flag
- `llvm.smul.with.overflow` - signed multiplication with overflow flag

These intrinsics return a struct `{ result, overflow_bit }`. Check the overflow bit and return an Error.Overflow if set.

### Special Overflow Cases

**Minimum integer negation**:

```stone
min_int := -9_223_372_036_854_775_808
abs(min_int)  # Error.Overflow (|-9223372036854775808| = 9223372036854775808 > max_int)
```

**Division special case**: Division never overflows except:

```stone
min_int ÷ (-1)   # Error.Overflow (result would be 9223372036854775808)
```

## Division by Zero

Division and modulo by zero always raise runtime errors:

```stone
10 ÷ 0          # Error.DivisionByZero
remainder(10, 0) # Error.DivisionByZero
0 ÷ 0           # Error.DivisionByZero (WARNING: not NaN)
```

**Implementation**: Explicit check before LLVM division:

```llvm
%is_zero = icmp eq i64 %divisor, 0
br i1 %is_zero, label %error, label %do_division

error:
  call void @raise_division_by_zero_error()
  unreachable

do_division:
  %result = sdiv i64 %dividend, %divisor
```

## Implementation as Function Calls

Arithmetic operators desugar to function calls:

```stone
# Operator syntax
a + b           # Desugars to: +(a, b)
a − b           # Desugars to: −(a, b)
a × b           # Desugars to: ×(a, b)
a ÷ b           # Desugars to: ÷(a, b)
```

This allows:

- Passing operators as higher-order functions
- Uniform function call semantics
- No special-case inlining (JIT/optimizer can inline later)

**Example: Higher-order usage**:

```stone
# Reduce with sum
reduce(numbers, +)   # Sum all numbers

# Map with product (partially applied)
double := λ(n) { ×(n, 2) }
map(numbers, double)
```

## Grammar

No special grammar rules for each operator - treat as binary expressions:

```ruby
# In grammar
rule(:expr) { 
  comparison_expr 
}

rule(:comparison_expr) { 
  binary_expr + (ws! + comparison_op + ws! + binary_expr).maybe 
}

rule(:comparison_op) { 
  terminal { /<=|>=|<|>|==|!=/ }
}

rule(:binary_expr) {
  primary_expr + (ws! + binary_op + ws! + primary_expr).zero_or_more
}

rule(:binary_op) {
  terminal { /\+|\-|\−|\*|×|\/|÷|\^|/ }
}

rule(:primary_expr) {
  # Numbers, identifiers, function calls, parenthesized expressions, etc.
}
```

**Note**: Parser doesn't enforce precedence between operators - semantic analysis or runtime checks require parentheses when mixing operators.

## Type Considerations

### Current: Int Only

All arithmetic operates on 64-bit signed integers (Int64/i64).

### Future: Multiple Numeric Types

When Float, Rational, BigInt, Complex, etc. are added:

#### Type Promotion

```stone
# Mixed Int and Float
2 + 3.5         # 5.5 (Int promoted to Float)
10 ÷ 3.0        # 3.333... (Int promoted to Float)

# Rational preserves exactness
1 // 3 + 1 // 6  # 1 // 2 (rational arithmetic)

# BigInt never overflows
bigint(max_int) + bigint(1)  # Succeeds, becomes BigInt
```

**Rules** (future):

- Int + Float → Float
- Int + Rational → Rational
- Int + BigInt → BigInt
- Rational + Float → Float (loses exactness)
- Int + Complex → Complex

## Error Messages

Clear, actionable error messages:

```stone
# Overflow
9_223_372_036_854_775_807 + 1
# Error: Integer overflow in addition
#   Result would exceed maximum Int value (9223372036854775807)

# Division by zero
42 ÷ 0
# Error: Division by zero
#   Cannot divide 42 by 0

# Negative exponent
2 ^ (-3)
# Error: Negative exponent not supported for integer exponentiation
#   Use Float type for negative exponents, or use: 1 ÷ (2 ^ 3)
```

## Test Cases

```ruby
RSpec.describe "Arithmetic Operators" do
  describe "addition (+)" do
    it "adds positive integers"
    it "adds negative integers"
    it "adds zero"
    it "is commutative"
    it "raises error on overflow"
    it "works as function: sum(a, b)"
  end

  describe "subtraction (-)" do
    it "subtracts positive integers"
    it "subtracts negative integers"
    it "subtracts zero"
    it "raises error on underflow"
    it "works as function: difference(a, b)"
  end

  describe "multiplication (×)" do
    it "multiplies positive integers"
    it "multiplies negative integers"
    it "multiplies by zero"
    it "multiplies by one"
    it "is commutative"
    it "raises error on overflow"
    it "works as function: product(a, b)"
    it "accepts both × and * symbols"
  end

  describe "division (÷)" do
    it "divides evenly"
    it "truncates toward zero"
    it "handles negative dividend"
    it "handles negative divisor"
    it "raises error on division by zero"
    it "raises error on min_int ÷ -1 overflow"
    it "works as function: quotient(a, b)"
    it "accepts both ÷ and / symbols"
  end

  describe "modulo (%)" do
    it "computes remainder"
    it "sign matches dividend"
    it "raises error on modulo by zero"
    it "works as function: remainder(a, b)"
  end

  describe "exponentiation (^)" do
    it "raises to positive power"
    it "returns 1 for power of 0"
    it "raises error on negative exponent"
    it "raises error on overflow"
    it "works as function: power(a, b)"
    it "accepts both ^ and ** symbols"
  end

  describe "negation" do
    it "negates positive integers"
    it "negates negative integers"
    it "negates zero"
    it "raises error on min_int"
  end

  describe "absolute value" do
    it "returns positive value for negative input"
    it "returns unchanged for positive input"
    it "returns zero for zero"
    it "raises error or handles min_int specially"
  end

  describe "operator as function" do
    it "can pass sum to higher-order functions"
    it "can pass product to higher-order functions"
  end

  describe "precedence" do
    it "requires parentheses when mixing operators"
    it "allows comparison with arithmetic: a + b == c"
    it "evaluates left-to-right for same operator"
  end
end
```

## Acceptance Criteria

- [ ] All arithmetic operators (+, -, ×, /, ^) are implemented
- [ ] Unicode operators (−, ×, ÷) work correctly
- [ ] All operations check for overflow and return appropriate Errors
- [ ] Division by zero returns an Error.DivisionByZero
- [ ] Operators can be used as functions
- [ ] No precedence between different arithmetic operators (enforce parentheses)
- [ ] Comparison operators have lower precedence than arithmetic
- [ ] All operators work with literals and constants
- [ ] Comprehensive tests cover edge cases
- [ ] Clear error messages for overflow and division by zero
- [ ] `make test` passes
- [ ] `make lint` passes

## Future Work

- [ ] Decimal type for financial calculations
- [ ] Rational type for exact fractional arithmetic
- [ ] FloatingPoint type with IEEE 754 arithmetic
- [ ] Type promotion rules between numeric types
- [ ] SIMD vector arithmetic?
