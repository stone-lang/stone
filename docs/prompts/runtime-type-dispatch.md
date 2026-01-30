# Runtime Type Dispatch

## Overview

Implement runtime type dispatch to branch execution based on
the runtime type of union-typed values.
This is required to properly handle union values when retrieving them ---
we need to know what type the value actually is to handle it correctly.

## Related Features

### Prerequisites

- Union types (representation, tagged union struct) (done)
- RTTI infrastructure (done)
- Type.of() on union fields extracts the runtime type (done)

### Enables

- Safe nullable handling throughout the language
- Error handling patterns (Result types)
- Algebraic data type patterns
- Recursive data structure traversal

## Problem Statement

Union-typed fields store values as tagged unions: `{ ptr type_tag, [N x i8] payload }`.
When accessing a union field and returning to Ruby, we lose type context:

- `Bool` payload is 0 or 1, indistinguishable from `Int(0)` or `Int(1)`
- `String` payload is a pointer, needs conversion to string
- Record payloads are pointers, can't chain property access without casting

## Goals

1. Provide a way to branch based on the runtime type of a union value
2. Enable safe extraction of typed values from unions
3. Unblock pending union type tests
4. Future support for exhaustiveness checking (all union alternatives handled)

## Non-Goals

We don't need to worry about pattern matching yet.

## Use Cases

### Bool/Int Disambiguation

```stone
Box := Record(value :: Bool | Int)
b := Box(TRUE)
# Need to know it's Bool to return TRUE (not 1)
```

### NULL Detection

```stone
Box := Record(value :: Int | Null)
b := Box(NULL)
# Need to distinguish NULL from Int(0)
```

### Chained Record Access

```stone
IntList := Record(first :: Int, rest :: IntList | Null)
list := IntList(1, IntList(2, NULL))
list.rest.first  # Need to cast `rest` to IntList before accessing .first
```

## Design Considerations

**Important**: Stone has no keywords. All control flow uses function-like syntax,
e.g., `if(condition, { then }, { else })`. Pattern matching must follow this pattern.

## As-Built Implementation

### Approach: Heap-Allocated Union for Ambiguous Types

For unions where types cannot be distinguished by value alone (currently Bool | Int),
the union struct is heap-allocated via `malloc` and a pointer is returned to Ruby.
Ruby then reads both the type tag and payload from heap memory to correctly interpret the value.

Key insight: FFI cannot return structs by value, and stack-allocated pointers are
invalid after function return. Heap allocation solves both problems.

### Changes Made

#### `lib/stone/type.rb`

- Added `Union#needs_runtime_type_tag?` method that identifies unions where
  types are ambiguous (currently: unions containing both Bool and Int)

#### `lib/stone/ast/property_access.rb`

- Added `heap_allocate_union` method that calls `malloc` to allocate heap memory,
  stores the union struct, and returns the pointer
- Added `declare_malloc` helper to declare the malloc function in LLVM IR
- Modified `extract_union_payload` to use heap allocation when `needs_runtime_type_tag?`

#### `lib/stone/ast/program_unit/top_function.rb`

- Added `heap_allocated_union_field_access?` to detect when the return value
  is a heap-allocated union pointer (so the return type is `ptr` not `i64`)

#### `lib/stone/ast/program_unit.rb`

- Added `HeapUnionConverter` class that reads from heap memory via FFI:
    - Reads type tag pointer (offset 0)
    - Reads type name string from RTTI struct
    - Reads and converts payload based on type name
- Added `:heap_union_ptr` result type handling in `last_expression_type` and `convert_to_ruby`

### Memory Management

The heap-allocated memory is never freed. This is acceptable because it only happens
at the boundary between LLVM JIT and Ruby (returning the final evaluation result),
right before the JIT engine is disposed.

### Design Decisions

1. **Heap vs stack**: Stack pointers are invalid after function return.
   FFI cannot return structs by value. Heap allocation is the simplest solution.
2. **Read type name string vs compare pointer addresses**: Comparing RTTI pointer
   addresses failed because `pointer_to_global` returned different addresses.
   Reading the type name string from the RTTI struct is more robust.
3. **Targeted approach**: Only unions that actually need disambiguation (Bool | Int)
   use heap allocation. Other unions continue using the existing extraction paths.

## Testing

Tests that were unblocked by this implementation:

- `"extracts Bool from Bool | Int union"` - Bool TRUE returns `true`
- Added: Bool FALSE returns `false`, Int 0 returns `0`, Int 1 returns `1`, Int 42 returns `42`

Previously unblocked tests (by earlier work):

- `"allows Bool | Null field with Bool value"` - Bool conversion
- `"allows Bool | Null field with NULL value"` - NULL detection
- `"allows Int | String field with String value"` - String conversion
- `"allows Record field with union type"` - Record access through union
- `"allows union of record types"` - Record access through union
- `"allows recursive type with NULL terminator"` - Chained access

## Wrap-Up

Once you've completed the implementation:

- [x] Update this file with as-built changes
- [ ] Include this updated file as part of the commit
- [ ] Add any lessons learned to your "memory"
- [ ] Run the `/retro` command
