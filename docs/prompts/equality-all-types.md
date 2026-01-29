# Universal Equality Operators

## Overview

Extend the equality operators (`==` and `!=`) to work with any type in Stone.
This feature enables comparing values of any type, which is essential for
pattern matching, error handling, and general-purpose programming.

Ask any questions up front, as much as possible. Once your questions have been answered, you may continue all the way to committing.

## Relationship to Other Features

### Prerequisites

- Basic type system with primitives
- Runtime type information, type-based dispatch
- Record types
- NULL literal and Null type

### Enables

- Error type comparisons (checking if result is an error)
- Pattern matching (future)
- Collection operations (finding elements, deduplication)
- Hash-based data structures (future - requires consistent hashing)

### Related

- Union types - equality must handle union-typed values

## Goals

1. `==` and `!=` work for all primitive types (Int, Bool, String, Null)
2. `==` and `!=` work for record types (structural equality, once we've confirmed type equality)
3. `==` and `!=` work for comparing any value to NULL
4. `==` and `!=` work across types (always returns FALSE for different types)
5. `!=` is the logical negation of `==`
6. Document plans to allow equality **between** types, like `1.0 == 1`
    - Put in `docs/prompts`, using a similar format to others in that directory

## Motivation

Universal equality is fundamental for:

```stone
# Error handling (comparing with Error types)
result := riskyOperation()
if(result == Error.DivisionByZero, { handleError() }, { useResult(result) })

# NULL checks
if(value == NULL, { useDefault() }, { process(value) })

# Record comparison
p1 := Point(1, 2)
p2 := Point(1, 2)
p1 == p2  # TRUE - structural equality

# General conditionals
if(status == "ready", { start() }, { wait() })
```

## Design Decisions

### Operators and Functions

The `==` and `!=` operators (and their UTF-8 equivalents) should desugar to functions
with the following default definitions:

``` stone
== := λ(left, right) { equals?(left, right) }
!= := λ(left, right) { !(==(left, right)) }
```

### Structural Equality for Records

Records are compared field-by-field. Two records are equal if:

- They have the same type (same record definition)
- All corresponding fields are equal (recursively)

```stone
Point := Record(x :: Int, y :: Int)
p1 := Point(1, 2)
p2 := Point(1, 2)
p3 := Point(1, 3)

p1 == p2  # TRUE - same type, same field values
p1 == p3  # FALSE - different y values
```

Of course, if the records both have the same pointer address, we don't need to check the fields.

### Cross-Type Comparison

Comparing values of different types always returns FALSE (never an error):

```stone
42 == "42"       # FALSE - Int vs String
42 == TRUE       # FALSE - Int vs Bool
Point(1,2) == 1  # FALSE - Record vs Int
```

### NULL Comparison

NULL equals NULL, and nothing else equals NULL:

```stone
NULL == NULL     # TRUE
42 == NULL       # FALSE
NULL == 42       # FALSE
"" == NULL       # FALSE
```

### Reference vs Value Equality

Stone uses **value equality** (structural), not reference equality:

```stone
# Two separately constructed records with same values are equal
p1 := Point(1, 2)
p2 := Point(1, 2)
p1 == p2  # TRUE (value equality)
```

Of course, if both sides of the equation reference the same value, we know they are equal
without having to compare the structures.

### Function Equality

Functions are compared by reference (pointer equality), not by definition:

```stone
f := λ(x) { x + 1 }
g := λ(x) { x + 1 }
h := f

f == g  # FALSE - different function instances
f == h  # TRUE - same function reference
```

NOTE: In the future, we will likely "fix" this by looking at the text and/or ASTs
of the 2 functions being compared.
That will still miss some cases, where the functions are logically equivalent
(returning the same values for the same outputs) but consist of different code.

### Union Type Equality

For union-typed values, equality compares the actual runtime values:

```stone
myfunc := λ(x :: Int | Null, y :: Int | Null, z :: Int | Null) {
    # Assuming we call myfunc(42, 42, NULL):
    x == y  # TRUE - both are Int 42
    x == z  # FALSE - Int vs Null
    x == 42 # TRUE - compares underlying values
}
```

## Usage Examples

### Basic Equality

```stone
# Integers
1 == 1           # TRUE
1 == 2           # FALSE
1 != 2           # TRUE

# Booleans
TRUE == TRUE     # TRUE
TRUE == FALSE    # FALSE
TRUE != FALSE    # TRUE

# Strings
"hello" == "hello"  # TRUE
"hello" == "world"  # FALSE
"" == ""            # TRUE
```

### Record Equality

```stone
Person := Record(name :: String, age :: Int)

alice := Person("Alice", 30)
also_alice := Person("Alice", 30)
bob := Person("Bob", 25)

alice == also_alice  # TRUE
alice == bob         # FALSE
alice != bob         # TRUE
```

### Nested Record Equality

```stone
Point := Record(x :: Int, y :: Int)
Rect := Record(origin :: Point, size :: Point)

r1 := Rect(Point(0, 0), Point(10, 20))
r2 := Rect(Point(0, 0), Point(10, 20))
r3 := Rect(Point(1, 1), Point(10, 20))

r1 == r2  # TRUE - deep equality
r1 == r3  # FALSE - different origin
```

### Conditional Logic

```stone
# With error types
divide := λ(a, b) {
  if(b == 0,
    { Error.DivisionByZero("Cannot divide by zero") },
    { a / b }
  )
}

result := divide(10, 0)
if(Type.of(result) == Error.DivisionByZero,
  { print("Division error!") },
  { print("Result: " + result.to_s) }
)
```

## Implementation Considerations

As always, we do TDD and write test cases before we start coding.

### Type-Based Dispatch

The equality operation needs to dispatch based on types (known at compile time or runtime):

1. If types are different, return FALSE
2. If both are primitives, compare values directly
3. If both are records of the same type, compare fields recursively
4. If both are functions, compare pointers

### LLVM Implementation

For primitive types, use direct comparison:

- Int: `icmp eq i64 %a, %b`
- Bool: `icmp eq i1 %a, %b`

For Strings:

1. Check size first; 2 strings of different sized cannot be equal
2. Check pointers (to C-style 0-terminated strings)
3. Check hashed values of the 2 strings
    - Will require adding `hashed` as a computed property of a String
        - Let's use SHA256, unless you have a better idea
4. Byte-by-byte comparison (probably optimized to use larger chunks than bytes)

For Record types:

1. Check pointers; pointers to the same memory location are equal (given their types are equal)
2. Check hashed values of the 2 records
    - Will require adding `hashed` as a computed property of Records
        - Let's use SHA256, unless you have a better idea
        - Hmm, how would we hash nested values? Looking for advice here.
3. Compares each field recursively

### Performance

- Primitive comparisons should probably be single LLVM instructions
- Use hash values where appropriate to simplify/optimize comparisons
- Nested records may require recursive comparison
- Record comparisons are O(n) where n is the number of fields
- Short-circuit evaluation for records (fail fast on first mismatch)

## Acceptance Criteria

- [ ] `==` works for Int values
- [ ] `==` works for Bool values
- [ ] `==` works for String values
- [ ] `==` works for NULL comparisons
- [ ] `==` works for record types (structural equality)
- [ ] `==` returns FALSE for different types (no error)
- [ ] `!=` is the logical negation of `==` for all types
- [ ] Nested record comparison works correctly
- [ ] Function comparison uses reference equality
- [ ] Union-typed values compare by their actual runtime values
- [ ] All existing tests pass
- [ ] `make test` passes
- [ ] `make lint` passes

## Future Enhancements

- Deep vs shallow equality options
- Hashing that is consistent with equality (for hash maps/sets)
- Pattern matching as cleaner syntax for type-based comparison
- Custom equality methods (`Type@==`) for user-defined equality semantics
- Memoization of computed properties will improve performance of hash comparisons

## Wrap-Up

Once you've completed the implementation:

- Update this file with any as-built changes we made to the design
- Include this updated file as part of the commit
- Add any lessons learned to your "memory"
- Run the `/retro` command
