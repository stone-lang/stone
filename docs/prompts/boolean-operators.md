# Boolean Operators

## Overview

Implement Boolean/logical operators for Stone.
These operators work on Bool type (TRUE/FALSE) and are essential for conditional logic.
Most Boolean operations should be inlined for performance.

## Design Decisions

### Mixed Operator Detection

**Decision**: Transform-time error (after parsing, before LLVM generation).

When mixing different Boolean operators without parentheses (e.g., `a ∧ b ∨ c`),
the error is raised during the AST transformation phase. This follows the same pattern
as arithmetic operators.

### Operator vs Function Naming

**Decision**: Primitive functions use descriptive names; operators are Stone-level wrappers.

- `and`, `or`, `xor`, `not` are the primitive functions using LLVM instructions
- `∧`, `∨`, `⊻`, `¬` (and ASCII alternatives `&&`, `||`, `!`) are Stone-level operators
- This allows operators to be redefined for other types if needed

## Implementation Plan

### Phase 1: Primitive Functions (built_ins.rb)

1. Add `and(a: Bool, b: Bool) -> Bool` using LLVM `and i1` instruction
2. Add `or(a: Bool, b: Bool) -> Bool` using LLVM `or i1` instruction
3. Add `xor(a: Bool, b: Bool) -> Bool` using LLVM `xor i1` instruction
4. Add `not(a: Bool) -> Bool` using LLVM `xor i1 %a, 1` instruction

### Phase 2: Grammar Updates (grammar.rb)

1. Update identifier pattern to include boolean operators: `∧|∨|⊻|&&|\|\||¬|!`
2. Ensure multi-character operators (`&&`, `||`) are recognized before single-character ones

### Phase 3: Operator Aliases (prelude.stone)

Add function definitions that call primitives:

```stone
∧(a, b) := { and(a, b) }
∨(a, b) := { or(a, b) }
⊻(a, b) := { xor(a, b) }
¬(a) := { not(a) }
!(a) := { not(a) }
&&(a, b) := { and(a, b) }
||(a, b) := { or(a, b) }
```

### Phase 4: Mixing Detection (transform.rb)

1. Create a helper to identify boolean operators (∧, ∨, ⊻, &&, ||)
2. In comparison_operation transform, check if operators are all boolean
3. If mixing boolean operators, raise error requiring parentheses
4. Add TODO comment about potential issue: `a < b ∧ c > d` being parsed as `a < (b ∧ c) > d`

### Phase 5: TODOs

1. Add TODO: "Overload `==` and `!=` for Bool type once we support function overloading"
2. Add note about mixing boolean ops with comparisons without parens (operator precedence issue)

### Files to Modify

- `lib/stone/built_ins.rb` - Add primitive functions
- `lib/stone/grammar.rb` - Add operators to identifier pattern
- `lib/stone/prelude.stone` - Add operator aliases
- `lib/stone/transform.rb` - Add mixing detection for boolean operators

## Boolean Type

Stone has a Bool type with two values:

- `TRUE` - represented as i1 value 1 in LLVM
- `FALSE` - represented as i1 value 0 in LLVM

## Logical Operators

### Logical AND: `∧`, `&&`

Logical AND uses the Unicode  (U+2227), or 2 ASCII ampersands `&&`.
I recommend that editors, formatters, and linters *normalize* these to the
**logical and** (U+2227).

Returns TRUE only if both operands are TRUE.

```stone
# Logical AND
TRUE ∧ TRUE        # TRUE
TRUE ∧ FALSE       # FALSE
FALSE ∧ TRUE       # FALSE
FALSE ∧ FALSE      # FALSE

# Desugars to a function call:
∧(a, b)
∧(a, b, c)  # if/once we have varargs support; otherwise `∧((a, b), c)`

# The default definition is:
∧(a, b) := { and(a, b) }  # varargs, if/once we have support for them
```

#### Implement `and(a, b)`

**Truth Table**:

| A     | B     | A ∧ B |
| ----- | ----- | ----- |
| TRUE  | TRUE  | TRUE  |
| TRUE  | FALSE | FALSE |
| FALSE | TRUE  | FALSE |
| FALSE | FALSE | FALSE |

**Implementation**: LLVM `and` instruction on i1 values.

**No short-circuit evaluation**: Both operands are always evaluated.
Use `if` with blocks for conditional evaluation:

```stone
# Both sides always evaluated
result := condition1() ∧ condition2()  # Both functions called

# For short-circuit behavior, use if
result := if(condition1(), { condition2() }, { FALSE })
```

**Properties**:

- Commutative: `a ∧ b == b ∧ a`
- Associative: `(a ∧ b) ∧ c == a ∧ (b ∧ c)`
- Identity element: `TRUE`
- Zero element: `FALSE`

### Logical OR: `∨`, `||`

Logical OR uses the Unicode (U+2228), or 2 ASCII vertical bars `||`.
I recommend that editors, formatters, and linters *normalize* these to the
**logical or** (U+2228).

Returns TRUE if at least one operand is TRUE.

```stone
# Logical OR with Unicode
TRUE ∨ TRUE        # TRUE
TRUE ∨ FALSE       # TRUE
FALSE ∨ TRUE       # TRUE
FALSE ∨ FALSE      # FALSE

# Desugars to a function call:
∨(a, b)
∨(a, b, c)  # if/once we have varargs support; otherwise `∨(∨(a, b), c)`

# The default definition is:
∨(a, b) := { or(a, b) }  # varargs, if/once we have support for them
```

#### Implement `or(a, b)`

**Truth Table**:

| A     | B     | A ∨ B |
| ----- | ----- | ----- |
| TRUE  | TRUE  | TRUE  |
| TRUE  | FALSE | TRUE  |
| FALSE | TRUE  | TRUE  |
| FALSE | FALSE | FALSE |

**Implementation**: LLVM `or` instruction on i1 values.

**No short-circuit evaluation**: Both operands are always evaluated.
Use `if` with blocks for conditional evaluation:

```stone
# Both sides always evaluated
result := check1() ∨ check2()  # Both functions called

# For short-circuit behavior, use if
result := if(check1(), { TRUE }, { check2() })
```

**Properties**:

- Commutative: `a ∨ b == b ∨ a`
- Associative: `(a ∨ b) ∨ c == a ∨ (b ∨ c)`
- Identity element: `FALSE`
- Zero element: `TRUE`

### Logical NOT: `¬`, `!`

Returns the opposite Boolean value.

Logical NOT uses the Unicode `¬` (U+00AC) or the ASCII exclamation mark `!`.
I recommend that editors, formatters, and linters *normalize* these to the
**logical not** (U+00AC).

```stone
# Using Bool@not property (already exists)
TRUE.not           # FALSE
FALSE.not          # TRUE

# Function form
not(TRUE)          # FALSE
not(FALSE)         # TRUE

# Symbolic form
¬(TRUE)           # FALSE
¬(FALSE)          # TRUE
!(FALSE)          # TRUE

# Double negation
TRUE.not.not       # TRUE
not(not(FALSE))    # FALSE
¬(¬(FALSE))       # FALSE
!(!(FALSE))       # FALSE
```

#### Implement `not(a)`

**Implementation**: LLVM `xor` instruction with 1 (i.e., `xor value, 1`).

**Properties**:

- Involution: `not(not(a)) == a`

**Note**: No (prefix) operator for now.
Use one of the functions or the property: `¬(b)`, `!(b)`, `not(b)`, `b.not`.

### Logical XOR: `⊻`

Returns TRUE if operands have different values (exclusive or).

Logical XOR uses the Unicode `⊻` (U+229B).
The inequality operator (`!=` or `≠` (U+2260)) can also be used as an alternative for Booleans,
but note that it has a lower precedence than the Boolean operators.

```stone
# Logical XOR with Unicode
TRUE ⊻ TRUE        # FALSE (both same)
TRUE ⊻ FALSE       # TRUE (different)
FALSE ⊻ TRUE       # TRUE (different)
FALSE ⊻ FALSE      # FALSE (both same)

# Alternative: not-equal works for Booleans
TRUE ≠ FALSE       # TRUE
TRUE ≠ TRUE        # FALSE

# ASCII alternative
TRUE != FALSE      # TRUE

# Function form
xor(TRUE, FALSE)   # TRUE
xor(TRUE, TRUE)    # FALSE
```

#### Implement `xor(a, b)`

**Truth Table**:

| A     | B     | A ⊻ B |
| ----- | ----- | ----- |
| TRUE  | TRUE  | FALSE |
| TRUE  | FALSE | TRUE  |
| FALSE | TRUE  | TRUE  |
| FALSE | FALSE | FALSE |

**Implementation**: LLVM `xor` instruction on i1 values.

**Properties**:

- Commutative: `a ⊻ b == b ⊻ a`
- Associative: `(a ⊻ b) ⊻ c == a ⊻ (b ⊻ c)`
- Identity element: `FALSE`
- Self-inverse: `a ⊻ a == FALSE`

## Operator Syntax Summary

| Operation | Unicode Symbol | ASCII Alt | Function Name |
| --------- | -------------- | --------- | ------------- |
| AND       | `∧` (U+2227)   | —         | `and(a, b)`   |
| OR        | `∨` (U+2228)   | —         | `or(a, b)`    |
| NOT       | `¬` (U+00AC)   | —         | `not(a)`      |
| XOR       | `⊻` (U+2295)   | —         | `xor(a, b)`   |

## Operator Precedence and Mixing

**No precedence between Boolean operators** - parentheses are required when mixing AND, OR, XOR:

```stone
# Error: ambiguous
a ∧ b ∨ c       # Error.MixedOperators: Use parentheses to explicitly group operations.

# Explicit grouping required
a ∧ (b ∨ c)     # (a AND b) OR c
(a ∧ b) ∨ c     # a AND (b OR c)

# Single operator is fine
a ∧ b ∧ c       # OK: left-to-right
a ∨ b ∨ c       # OK: left-to-right
```

**Rationale**: Requiring parentheses makes intent explicit and prevents subtle bugs from precedence misunderstanding.

## No Short-Circuit Evaluation

Boolean operators always evaluate both operands.
This simplifies implementation and makes behavior predictable.

**Benefits**:

- Simpler semantics - operators are pure functions
- Easier to reason about - no hidden control flow
- Explicit control flow with `if` and blocks
- Consistent with treating operators as functions

**Trade-off**: More verbose for conditional short-circuit patterns, but intent is clearer.

## Comparison Operators (Boolean Results)

Comparison operators are separate from Boolean operators and are covered in their own documentation.
They return Boolean results:

```stone
# Comparison operators (not covered here)
5 == 5              # TRUE
3 < 5               # TRUE
10 >= 5             # TRUE
```

These can be combined with Boolean operators:

```stone
# Comparison has lower precedence than Boolean ops
(x > 0) ∧ (x < 10)  # TRUE if x in range (0, 10)
(a == b) ∨ (a == c) # TRUE if a matches b or c
```

**Note**: Parentheses required when mixing Boolean operators,
but comparisons bind less tightly, so:

```stone
a ∧ b == TRUE
x > 0 ∧ x < 10      # Parsed as: x > (0 ∧ x) < 10 - probably not what was intended
(x > 0) ∧ (x < 10)  # Correct: explicitly grouped comparisons
```

## Type Safety: No Truthy/Falsy Values

Stone requires strict Boolean types in Boolean contexts. No implicit conversions:

```stone
# Explicit comparison required
x := 5
if(x != 0, { ... }, { ... })  # Good: explicit comparison

# Not allowed
if(x, { ... }, { ... })  # Error: x is Int, not Boolean

# Explicit conversion if desired
Int@as_Boolean := λ(this) { this != 0 }
```

**Rationale**: Reduces bugs and makes intent clear.
No confusion about what values are "truthy".

### Explicit Conversion Methods (If Desired)

```stone
# Int to Boolean
Int@as_Boolean := λ(this) { this != 0 }
5.as_Boolean   # TRUE
0.as_Boolean   # FALSE

# String to Boolean
String@as_Boolean := λ(this) { this.empty?.not && this != "false" && this != "0" && this != "no" }
"hello".as_Boolean   # TRUE
"true".as_Boolean   # TRUE
"false".as_Boolean  # FALSE
"0".as_Boolean      # FALSE
"no".as_Boolean     # FALSE
"".as_Boolean       # FALSE
```

## Boolean Algebra Laws

Useful for optimization and reasoning about Boolean expressions:

### Identity Laws

- `a ∧ TRUE == a`
- `a ∨ FALSE == a`

### Zero Laws

- `a ∧ FALSE == FALSE`
- `a ∨ TRUE == TRUE`

### Complement Laws

- `a ∧ not(a) == FALSE`
- `a ∨ not(a) == TRUE`

### Idempotent Laws

- `a ∧ a == a`
- `a ∨ a == a`

### De Morgan's Laws

- `not(a ∧ b) == not(a) ∨ not(b)`
- `not(a ∨ b) == not(a) ∧ not(b)`

### Associativity

- `(a ∧ b) ∧ c == a ∧ (b ∧ c)`
- `(a ∨ b) ∨ c == a ∨ (b ∨ c)`

### Commutativity

- `a ∧ b == b ∧ a`
- `a ∨ b == b ∨ a`

### Distributivity

- `a ∧ (b ∨ c) == (a ∧ b) ∨ (a ∧ c)`
- `a ∨ (b ∧ c) == (a ∨ b) ∧ (a ∨ c)`

## Implementation Notes

### LLVM Instructions

All Boolean operations should be lowered to LLVM instructions:

- AND: `and i1 %a, %b`
- OR: `or i1 %a, %b`
- NOT: `xor i1 %a, 1`
- XOR: `xor i1 %a, %b`

These are extremely fast and should be inlined when possible.

### Operators as Functions

Boolean operators can be used as first-class functions:

```stone
# Pass operator as function
all_true := reduce(bools, ∧)     # Check if all are TRUE
all_true := reduce(bools, and)   # Check if all are TRUE
any_true := reduce(bools, ∨)    # Check if any are TRUE
any_true := reduce(bools, or)   # Check if any are TRUE
```

### Optimization

Boolean expressions are ideal for optimization:

- Constant folding: `TRUE ∧ x` → `x`
- Common subexpression elimination
- Algebraic simplification using Boolean laws
- Dead code elimination: `if(FALSE, { ... }, { ... })` → second branch

## Grammar

No special grammar rules needed - treat as binary expressions:

```ruby
# In grammar
rule(:expr) { 
  comparison_expr 
}

rule(:binary_expr) {
  primary_expr + (ws! + binary_op + ws! + primary_expr).zero_or_more
}

rule(:binary_op) {
  terminal { /∧|∨|⊻|≠/ }
}

rule(:primary_expr) {
  # Booleans, identifiers, function calls, parenthesized expressions, etc.
}
```

**Note**: Parser doesn't enforce precedence between Boolean operators - semantic analysis requires parentheses when mixing operators.

Alternatively, treat operators as function calls:

```stone
and(a, b)       # Function call syntax
or(a, b)
xor(a, b)
not(a)
```

## Test Cases

```ruby
RSpec.describe "Boolean Operators" do
  describe "logical AND (∧)" do
    it "returns TRUE when both operands are TRUE"
    it "returns FALSE when left is FALSE"
    it "returns FALSE when right is FALSE"
    it "returns FALSE when both are FALSE"
    it "evaluates both operands (no short-circuit)"
    it "is commutative"
    it "is associative"
    it "works as function: and(a, b)"
  end

  describe "logical OR (∨)" do
    it "returns TRUE when left is TRUE"
    it "returns TRUE when right is TRUE"
    it "returns TRUE when both are TRUE"
    it "returns FALSE when both are FALSE"
    it "evaluates both operands (no short-circuit)"
    it "is commutative"
    it "is associative"
    it "works as function: or(a, b)"
  end

  describe "logical NOT (not)" do
    it "negates TRUE to FALSE"
    it "negates FALSE to TRUE"
    it "double negation returns original"
    it "works as method: TRUE.not"
    it "works as function: not(TRUE)"
  end

  describe "logical XOR (⊻)" do
    it "returns TRUE when operands differ"
    it "returns FALSE when operands are same"
    it "is commutative"
    it "is associative"
    it "works as function: xor(a, b)"
    it "equivalent to != for Booleans"
  end

  describe "operator mixing" do
    it "requires parentheses when mixing AND and OR"
    it "requires parentheses when mixing AND and XOR"
    it "requires parentheses when mixing OR and XOR"
    it "allows repeated same operator"
  end

  describe "De Morgan's laws" do
    it "not(a ∧ b) == not(a) ∨ not(b)"
    it "not(a ∨ b) == not(a) ∧ not(b)"
  end

  describe "type safety" do
    it "requires Bool type, not truthy values"
    it "rejects Int in Boolean context"
    it "rejects String in Boolean context"
  end

  describe "as first-class functions" do
    it "can pass and() to higher-order functions"
    it "can pass or() to higher-order functions"
    it "can pass xor() to higher-order functions"
  end
end
```

## Acceptance Criteria

- [ ] Logical operators (∧, ∨, ⊻) are implemented
- [ ] Unicode symbols work correctly
- [ ] Function forms (and, or, xor, not, ¬, !) work correctly
- [ ] No short-circuit evaluation (both operands always evaluated)
- [ ] No precedence between different Boolean operators (requires parentheses)
- [ ] Boolean algebra laws hold (De Morgan's, etc.)
- [ ] Type safety enforced (no truthy/falsy coercion)
- [ ] All operators work with constants and variables
- [ ] Comprehensive tests cover edge cases
- [ ] `make test` passes
- [ ] `make lint` passes

## Future Work

- [ ] Bitwise operations for Int (not planning for any symbolic operators)
- [ ] Three-valued logic (TRUE, FALSE, UNKNOWN/NULL) for database operations
- [ ] Pattern matching as alternative to complex Boolean expressions
- [ ] Boolean expression simplification optimization passes
- [ ] SIMD Boolean vector operations
