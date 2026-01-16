# Union Type Representation in Records

## Prerequisites

This feature depends on **runtime-type-info.md** being implemented first. Union types use runtime type constants for tagging.

## Current State

Union type syntax has been implemented for type annotations (see `docs/prompts/union-types.md`). Union types can be:

- Declared: `x :: Int | String`
- Used in function signatures: `f :: (Int | Null) -> Int`
- Stored in scope with proper `Stone::Type::Union` objects

However, union types cannot yet be used in Record fields:

```stone
Box := Record(value :: Int | Null)  # ERROR: Unknown type: Int | Null
```

The error occurs in `lib/stone/ast/record_definition.rb` in `llvm_type_for_field`, which looks up the LLVM type by name string but doesn't handle union type names.

## Problem

Union types require runtime representation to:

1. Store values of different types in the same field
2. Track which type variant is currently stored (for `Type.of()`)
3. Allow runtime type checking and pattern matching (future)

## Requirements

### Must Have

- Record fields can use union type annotations (any union, not just nullable)
- Values of any alternative type can be assigned to union-typed fields
- NULL can be assigned to `T | Null` fields
- Field access returns the stored value (raw payload, not tagged struct)
- `Type.of()` on union-typed field returns the actual runtime type

### Deferred

- Type checking at assignment (no validation yet - trust the programmer)
- Pattern matching on union types

## Design Decisions

### Field Type Storage

Store `Stone::Type` objects (including `Stone::Type::Union`) directly in field definitions, not type name strings. This allows proper handling of union types without string parsing.

Update `field[:type]` to hold `Stone::Type` objects for ALL field types (not just unions). This is cleaner than mixing strings and Type objects. The `to_type(registry)` methods on type annotations already support this conversion.

### LLVM Representation: Tagged Union

Use a discriminated union with type pointer tag:

```llvm
%union_type = type { ptr, i64 }  ; type_tag, payload
```

- **type_tag**: Pointer to the runtime type constant (see runtime-type-info.md)
- **payload**: Either the value directly (if fits in i64) or a pointer to the value

Each union type gets its own LLVM struct type instance (not a shared type). This allows for potential future optimization where different unions might have different representations.

### Payload Rules

- **Fits in i64**: Store directly in payload
    - `Int` (i64) - stored directly
    - `Bool` (i1) - zero-extended to i64
    - `String` (i64 pointer-as-int) - stored directly
    - `Null` - payload is 0 (ignored, type tag is sufficient)
- **Doesn't fit in i64**: Store pointer to stack-allocated value
    - Record types (variable-sized structs) - pointer to struct
    - Other large types - pointer to value

### NULL Representation

NULL is represented with:

- type_tag = pointer to `@Stone.Type.Null` constant
- payload = 0 (value is irrelevant)

### Memory Allocation

- **No boxing**: Values are not heap-allocated for union storage
- **Stack allocation**: When a value doesn't fit in i64, allocate on stack and store pointer
- **Copy semantics**: Values are copied into the union payload (or stack slot)

**Future (with GC)**: With immutability, we can optimize by sharing references instead of copying. Once GC is implemented, large values could be heap-allocated and reference-counted or garbage-collected. The tagged union representation supports this - just change where the pointer points.

### Field Access Semantics

Field access on a union-typed field returns the **raw payload value**, not the tagged struct. Users should never see the tagging mechanism.

```stone
Box := Record(value :: Int | Null)
b := Box(42)
x := b.value   # x is i64 value 42, not a tagged struct
```

This means:

- For `Int` payload: return the i64 directly
- For `Bool` payload: extract and return i1
- For `String` payload: return the i64 (string pointer)
- For `Null`: return null pointer
- For Record payload: return the pointer, then load if needed

The caller cannot determine the runtime type from the returned value alone - they must use `Type.of()` before the access if they need type information.

### Type.of() on Union Fields

`Type.of()` extracts the type tag from the union representation:

```stone
Box := Record(value :: Int | Null)
b := Box(42)
Type.of(b.value).as_String   # "Int"

b2 := Box(NULL)
Type.of(b2.value).as_String  # "Null"
```

Implementation: In `TypeOfExpression#to_llir`, check if the inner expression is a `PropertyAccess` that returns a union-typed field. If so, generate code to extract the type_tag (first element of the tagged struct) instead of using the compile-time type. Keep `PropertyAccess` simple - it always returns the payload for field access.

### Type Widening

Assignment from narrower to wider union types is allowed:

```stone
x :: Int
y :: Int | Null
y := x   # Valid: Int is compatible with Int | Null
```

The existing `Stone::Type#compatible_with?` method handles this correctly:

- `Int.compatible_with?(Int | Null)` returns `true` (Int matches the Int alternative)
- `(Int | Null).compatible_with?(Int)` returns `false` (would require runtime check)

### Type Checking at Assignment

**Deferred**: No type validation at assignment time. The infrastructure is being set up; type checking will be added in a future phase.

## Implementation Steps

1. **Update field type storage**
   - Modify record field parsing to store `Stone::Type` objects for unions
   - Update `RecordDefinition` to handle both string and Type object field types

2. **Add union LLVM type**
   - Define `%union_type = type { ptr, i64 }` struct
   - Add `llvm_type` method to `Stone::Type::Union` returning this struct type

3. **Update `llvm_type_for_field`**
   - Check if field type is a `Stone::Type::Union`
   - Return the union's LLVM type

4. **Update record instantiation**
   - When assigning to a union-typed field, create the tagged struct
   - Set type_tag to appropriate runtime type constant
   - Pack payload according to payload rules

5. **Update field access**
   - When accessing a union-typed field, extract and return the payload
   - Handle different payload types (direct i64, pointer to record, etc.)

6. **Update Type.of()**
   - For union-typed expressions, extract type_tag instead of using compile-time type

## Affected Files

- `lib/stone/ast/record_definition.rb` - Field type lookup, LLVM type generation
- `lib/stone/type.rb` - Add `llvm_type` to `Stone::Type::Union`
- `lib/stone/ast/record_instantiation.rb` - Create tagged union values
- `lib/stone/ast/property_access.rb` - Extract payload from union fields
- `lib/stone/ast/type_of_expression.rb` - Extract type tag for union values
- `lib/stone/transform.rb` - Parse union types in field annotations to Type objects
- `spec/language/types/union_type_spec.rb` - Enable pending tests, add new tests

## Test Cases

### Existing (Currently Pending)

See `spec/language/types/union_type_spec.rb` lines 104-144:

```ruby
it "allows nullable field with non-null value"
it "allows nullable field with NULL value"
it "allows multiple union-typed fields"
it "allows recursive type with NULL terminator"
```

### Additional Tests Needed

```ruby
# General unions (not just nullable)
it "allows Int | String field with Int value"
it "allows Int | String field with String value"

# Type.of() on union fields
it "returns Int type for Int value in union field"
it "returns Null type for NULL value in union field"
it "returns String type for String value in Int|String field"

# Type widening
it "allows assigning Int to Int | Null field"
it "allows assigning Int | Null to Int | String | Null field"

# Nested unions in records
it "allows Record field with union type"
it "allows union of record types"
```

## Edge Cases

### Self-Referential Records with Union

```stone
IntList := Record(first :: Int, rest :: IntList | Null)
```

The `rest` field is a union where one alternative (`IntList`) is the record being defined. Since records are represented as pointers in union payloads, this works naturally - the payload holds a pointer to an IntList struct (or null for the Null case).

### Union of Multiple Record Types

```stone
Shape := Record(kind :: String)
Circle := Record(radius :: Int)
Square := Record(side :: Int)
Container := Record(shape :: Circle | Square)
```

Both Circle and Square are record types, so both are stored as pointers in the payload. The type tag distinguishes which record type is stored.

### Bool in Unions

```stone
MaybeBool := Record(value :: Bool | Null)
```

Bool is i1 in LLVM but fits in i64. Zero-extend to i64 when storing, truncate to i1 when extracting.
