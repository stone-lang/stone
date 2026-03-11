# Error Types

## Overview

Implement a hierarchy of Error types in Stone.
Errors are values, not exceptions.
Functions that can fail return union types like `Int | Error.Overflow`,
and callers must explicitly handle the error case.
This follows the functional programming tradition of making failure explicit in the type system.

## Prerequisites

- Union types
- Record types with hierarchy/subtypes
    - or a mechanism to express type relationships
- Type annotations

## Goals

1. Define `Error` as a base error type
2. Define specific error subtypes: `Error.Overflow`, `Error.DivisionByZero`, etc.
    - And others, as you deem necessary
3. Errors carry a message and potentially other context
4. Functions return `T | Error` (or specific error subtypes) when they can fail
5. Callers must explicitly handle the error case for now
    - Later, we may add a mechanism to allow for auto-propagation of unhandled Error return values

## Motivation

Currently, operations that can fail (like division by zero or integer overflow) either:

- Halt execution with a runtime error
- Return undefined/incorrect values
- Require special sentinel values

With Error types:

```stone
# Safe division returns a union type
safeDiv :: (Int, Int) -> (Int | Error.DivisionByZero)
safeDiv := λ(a, b) {
  if(b == 0,
    { Error.DivisionByZero("Cannot divide by zero") },
    { a / b }
  )
}

# Caller must handle the error
result := safeDiv(10, 0)
if(result.is?(Error),
  { print("Error: " + result.message) },
  { print("Result: " + result.to_s) }
)
```

## Design Decisions

### Error Hierarchy Structure

Errors should form a hierarchy where specific errors are subtypes of `Error`:

```stone
Error                      # Base type
├── Error.Arithmetic       # Arithmetic operation errors
│   ├── Error.Overflow
│   ├── Error.Underflow
│   └── Error.DivisionByZero
├── Error.Index            # Indexing errors
│   ├── Error.OutOfBounds
│   └── Error.KeyNotFound
├── Error.Type             # Type-related errors
│   └── Error.TypeMismatch
└── Error.IO               # I/O errors (future)
```

The exact hierarchy is flexible and will grow with the language.

### Error Construction

Errors should be easy to construct with a message:

```stone
Error.DivisionByZero("Cannot divide by zero")
Error.Overflow("Integer overflow in addition")
```

### Error Properties

At minimum, errors should have:

- `message` - Human-readable description of the error

Potentially also:

- `kind` or type identification for pattern matching
- `context` - Additional data about the error (optional)

### Type Compatibility

An `Error.DivisionByZero` is an `Error`. This enables:

```stone
# Function can return any arithmetic error
calculate :: (Int, Int) -> (Int | Error.Arithmetic)

# Caller can match on specific error or general Error
```

### No Exception Handling

This implementation explicitly avoids exception-style control flow:

- No `try`/`catch`/`throw`
- No stack unwinding
- Errors are values that must be checked

Future work may add a propagation operator (like Rust's `?`) to reduce boilerplate.

## Usage Examples

### Basic Error Handling

```stone
# Function that can fail
parseInt :: (String) -> (Int | Error)
parseInt := λ(s) {
  # ... parsing logic ...
  if(parseSucceeded, { parsedValue }, { Error("Invalid integer: " + s) })
}

# Using the function
input := "42"
result := parseInt(input)
if(result.is?(Error),
  { 0 },  # Default value on error
  { result }
)
```

### Arithmetic with Overflow Detection

```stone
# Safe addition that detects overflow
safeAdd :: (Int, Int) -> (Int | Error.Overflow)

a := 9223372036854775807  # Max Int64
b := 1
result := safeAdd(a, b)
# result is Error.Overflow, not a wrapped/incorrect value
```

### Chaining Fallible Operations

```stone
# Without propagation operator, must check each step
step1 := operation1(input)
if(step1.is?(Error), { step1 }, {
  step2 := operation2(step1)
  if(step2.is?(Error), { step2 }, {
    operation3(step2)
  })
})
```

Future: A propagation operator would simplify this.

### Error Matching

```stone
result := riskyOperation()
if(result.is?(Error.DivisionByZero), {
  print("Division by zero!")
}, {
  if(result.is?(Error.Overflow), {
    print("Overflow!")
  }, {
    # Success case
    print("Result: " + result.to_s)
  })
})
```

## Implementation Considerations

### Representing the Hierarchy

Options include:

- Records with a type tag field
- Using the existing union type infrastructure with type tags
- A new "enum-like" or "sealed class" mechanism

The simplest approach may be to implement errors as records with a `kind` field, where specific error types set the kind appropriately.

### Type Checking

When checking if a value matches an error type:

- `value.is?(Error)` - true for any error
- `value.is?(Error.Arithmetic)` - true for Overflow, Underflow, DivisionByZero
- `value.is?(Error.DivisionByZero)` - true only for DivisionByZero

This requires either:

- Runtime type tags in the value
- A subtype relationship that the type checker understands

### Standard Error Types to Include

Initial set:

- `Error` - base type
- `Error.Overflow` - integer overflow
- `Error.Underflow` - integer underflow (if relevant)
- `Error.DivisionByZero` - division by zero

Later additions as needed:

- `Error.OutOfBounds` - index out of bounds
- `Error.KeyNotFound` - map/dict key not found
- `Error.ParseError` - parsing failures
- `Error.InvalidArgument` - general argument validation

## Acceptance Criteria

- [ ] `Error` type exists as a base error type
- [ ] Can create specific error subtypes (`Error.Overflow`, `Error.DivisionByZero`)
- [ ] Errors can be constructed with a message
- [ ] Errors have a `.message` property
- [ ] Can check if a value is an error with `.is?(Error)`
- [ ] Can check for specific error types with `.is?(Error.DivisionByZero)`
- [ ] Functions can declare error union return types: `(Int | Error)`
- [ ] Callers must handle the error case (type checker rejects ignoring errors)
- [ ] Error subtypes are compatible with their parent types
- [ ] All existing tests pass
- [ ] `make test` passes
- [ ] `make lint` passes

## Relationship to Other Features

### Prerequisites

- Union types - for `T | Error` return types
- Type annotations - for declaring error return types
- Runtime type information - for `.is?()` checks

### Enables

- Safe arithmetic operations that return errors instead of halting
- Result-style patterns common in functional programming
- Explicit error handling throughout the codebase

### Future Enhancements

- Error propagation operator (`?` or similar) to reduce boilerplate
- Pattern matching for cleaner error handling
- Stack traces or source location in errors
- Error chaining (wrapping one error in another)
- `Result(T, E)` type alias for `T | E`

## Notes

- Keep the initial implementation simple - just the base mechanism
- Don't over-engineer the hierarchy; let it grow organically with real use cases
- The goal is making errors explicit, not creating a comprehensive error catalog
- Consider how errors interact with the planned effect system (if any)

## Wrap-Up

Once you've completed the implementation:

- Update this file with any as-built changes we made to the design
- Include this updated file as part of the commit
- Add any lessons learned to your "memory"
- Run the `/retro` command
