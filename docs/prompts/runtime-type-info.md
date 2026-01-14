# Runtime Type Information

## Overview

Stone needs runtime type information (RTTI) to support:

- `Type.of(value)` returning runtime type of a value, when it cannot be determined at compile time
- `type.as_String` returning type name as a string
- Union type discrimination (knowing which alternative is stored)
- Future: reflection, serialization, debugging

## Current State

Types exist at compile time as `Stone::Type` objects in Ruby.
There is no runtime representation - type information is erased during LLVM code generation.

`Type.of()` is partially implemented but returns compile-time types, not runtime types. For union-typed values, it cannot determine the actual runtime type.

## Requirements

- Global constant for each type used in the program
- Primitive types: Int, Bool, String, Null, Type
- Record types: generated for each Record definition
- Function types: generated for each distinct function type
- Union types: generated for each distinct union that is used in a function type
    - Not needed for other union types
- `Type.of(value)` returns pointer to the value's type constant
- `type.as_String` returns the type's name
- Type equality via pointer comparison (`type1 == type2`)
    - Extend `==` to work with Type values (pointer comparison)
- Field information for record types (names, types, offsets)
    - Use a recursive FieldList record type for now
    - TODO: Change to `List(Field)` once generics are implemented
- Function type information (parameter types, return type)
- Type hierarchy/relationships
- `type.record?` returns TRUE for record types, FALSE otherwise
- `type.primitive?` returns TRUE for primitive types (Int, Bool, String, Null)
- `type.size` returns size in bytes
- `type.kind` returns type kind enum value
- `type.fields` returns FieldList for records, NULL for other types

## Type Kind Enum (Clarified)

```text
0 = primitive (Int, Bool, String, Null) - value types
1 = record
2 = union
3 = function
4 = type (metatype - semantically distinct from primitives)
```

Note: Type has kind=4 (not 0) because it's a metatype, not a value type.
The distinction matters for semantic clarity.

## Design

### Type Constant Structure

Each type has a global constant with this structure:

```llvm
%Stone.Type = type {
  ptr,    ; name - pointer to null-terminated string
  i64,    ; size - size in bytes (for value types)
  i8      ; kind - enum: 0=primitive, 1=record, 2=union, 3=function, 4=type
}

; Example for Int
@"Stone.Type.Int.name" = private constant [4 x i8] c"Int\00"
@Stone.Type.Int = constant %Stone.Type {
  ptr @"Stone.Type.Int.name",
  i64 8,
  i8 0
}
```


### Primitive Type Constants

Generate once, shared across all programs:

- `@Stone.Type.Int`
- `@Stone.Type.Bool`
- `@Stone.Type.String`
- `@Stone.Type.Null`
- `@Stone.Type.Type`

### Record Type Constants

Generated for each Record definition:

```stone
Point := Record(x :: Int, y :: Int)
```

Generates:

```llvm
@"Stone.Type.Point.name" = private constant [6 x i8] c"Point\00"
@Stone.Type.Point = constant %Stone.Type {
  ptr @"Stone.Type.Point.name",
  i64 16,  ; two i64 fields
  i8 1     ; record kind
}
```

### Union Type Constants

Generated for each distinct union type used within a function type:

```stone
x :: Int | Null
```

Generates:

```llvm
@"Stone.Type.Int|Null.name" = private constant [11 x i8] c"Int | Null\00"
@Stone.Type.Int|Null = constant %Stone.Type {
  ptr @"Stone.Type.Int|Null.name",
  i64 16,  ; tagged union size: ptr + i64
  i8 2     ; union kind
}
```

### Type.of() Implementation

For non-union values, `Type.of()` returns the compile-time known type constant:

```stone
Type.of(42)  ; returns @Stone.Type.Int
```

For union-typed values, `Type.of()` extracts the type tag from the tagged representation:

```stone
IntOrNull := Record(value :: Int | Null)
b := IntOrNull(42)
Type.of(b.value)  ; returns @Stone.Type.Int (extracted from tag)
```

### as_String Implementation

`as_String` on a type value loads the name pointer and returns it:

```llvm
; Given %type_ptr pointing to a Type
%name_ptr_ptr = getelementptr %Stone.Type, ptr %type_ptr, i32 0, i32 0
%name_ptr = load ptr, ptr %name_ptr_ptr
; %name_ptr is now the string to return
```

## Implementation Steps

1. Define `%Stone.Type` struct type in module initialization
2. Generate global constants for primitive types (Int, Bool, String, Null) and Type
3. Generate global constants for record types during record definition processing
4. Update `Type.of()` to return pointer to type constant
5. Implement `as_String` property access for Type values
6. Generate union type constants (needed for union-type-representation)

## Affected Files

- `lib/stone/ast/program_unit.rb` - Generate primitive type constants
- `lib/stone/ast/record_definition.rb` - Generate record type constants
- `lib/stone/ast/type_of_expression.rb` - Return type constant pointer
- `lib/stone/ast/property_access.rb` - Handle `as_String` on Type values
- `lib/stone/types.rb` - May need LLVM type info

## Testing

```stone
# Primitive types
Type.of(42).as_String           # "Int"
Type.of(TRUE).as_String         # "Bool"
Type.of("hello").as_String      # "String"
Type.of(NULL).as_String         # "Null"

# Record types
Point := Record(x :: Int, y :: Int)
p := Point(1, 2)
Type.of(p).as_String            # "Point"
Type.of(p).record?            # TRUE
Type.of(p).fields            # [("x", @Stone.Type.Int), ("y", @Stone.Type.Int)]  NOTE: May not be representable yet, given we don't have List yet. If so, punt and document.

# Type equality
Type.of(42) == Type.of(1)       # TRUE (both Int)
Type.of(42) == Type.of(TRUE)    # FALSE

# Type of Type
Type.of(Type.of(42)).as_String  # "Type"
```

## Compound Types

### Extended Record Metadata

```llvm
%Stone.Type.Record = type {
  %Stone.Type,  ; base type info
  ptr,           ; pointer to field info array
  i32            ; field count
}

%Stone.Field = type {
  ptr,  ; field name
  ptr,  ; field type (pointer to Type)
  i32,  ; size (in bits)
  i32,  ; offset in struct
  i32   ; alignment
}
```

### Extended Union Metadata

```llvm
%Stone.Type.Union = type {
  %Stone.Type,  ; base type info
  i32,              ; alternative count
  ptr               ; pointer to array of Type pointers
}
```

## Dependencies

None, other than types - this is foundational infrastructure.

## Dependents

- Union type representation (uses type constants for tagging)
- Pattern matching (uses type constants for case discrimination)
- Reflection APIs
- Serialization
