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

## As-Built Implementation

### Architecture

All equality operations use RTTI-based runtime dispatch:

1. Each argument is boxed as `(type_tag_ptr, value_ptr)` at the call site
2. `equals?` compares type tags first — different tags return FALSE
3. Same-type dispatch loads the `equals_fn` from the RTTI type struct
4. Type-specific equals function compares the actual values

### RTTI Type Struct

```llvm
%Stone.Type = type { ptr, i64, i8, ptr, ptr }
; Fields: name, size, kind, fields, equals_fn
```

Kind enum: 0=primitive, 1=record, 2=union, 3=function, 4=type(metatype)

### Primitive Equality

- Int: `__Int_equals__` — loads i64 values, `icmp eq`
- Bool: `__Bool_equals__` — loads i1 values, `icmp eq`
- String: `__String_equals__` — loads string pointers, calls libc `strcmp`, checks result == 0
- Null: `__Null_equals__` — always returns TRUE (both are Null)
- Type: `__Type_equals__` — loads pointers, `icmp eq`
- Function: `__Function_equals__` — loads pointers, `icmp eq` (reference equality)

### Record Equality

- Records generate a `__RecordName_equals__` function at definition time
- Compares all fields by AND-ing individual field comparisons
- Record-typed fields use pointer indirection (heap-allocated)
- Union-typed fields dispatch to `__union_equals__`

### Union Field Equality

- `__union_equals__` takes `(tag_a, payload_a, tag_b, payload_b)`
- Compares type tags first — different tags return FALSE
- Guards against null `equals_fn` pointer
- Runtime kind dispatch: records need extra load indirection, primitives pass payload directly

### Operators

- `equals?` — base tagged equality function
- `==` — alias for `equals?`
- `!=` — calls `equals?` and negates with `xor true`
- `≠` — alias for `!=`

### Not Yet Implemented (deferred)

- Pointer shortcut for records (same address = equal without field comparison)
- Hash-based comparison optimization for strings and records
- Short-circuit on first field mismatch (currently ANDs all fields)

## Acceptance Criteria

- [x] `==` works for Int values
- [x] `==` works for Bool values
- [x] `==` works for String values
- [x] `==` works for NULL comparisons
- [x] `==` works for record types (structural equality)
- [x] `==` returns FALSE for different types (no error)
- [x] `!=` is the logical negation of `==` for all types
- [x] Nested record comparison works correctly
- [x] Function comparison uses reference equality
- [x] Union-typed values compare by their actual runtime values
- [x] All existing tests pass
- [x] `make test` passes
- [x] `make lint` passes

## Future Enhancements

- Structural/semantic function equality (comparing ASTs or definitions)
- Cross-type equality coercion (e.g., `1.0 == 1`) — see `docs/prompts/cross-type-equality.md`
- Pointer shortcut for records (same address = equal without field comparison)
- Hash-based comparison optimization for strings and records
- Short-circuit record comparison (fail fast on first field mismatch)
- Deep vs shallow equality options
- Hashing that is consistent with equality (for hash maps/sets)
- Pattern matching as cleaner syntax for type-based comparison
- Custom equality methods (`Type@==`) for user-defined equality semantics

## Implementation Commits

- `615c9ba` — Implement universal equality with RTTI vtable dispatch
- `c9f1604` — Implement equality comparison for union-typed record fields
- `7766d9b` — Implement function reference equality (pointer comparison)
