# Generalize Lambda Parameter Types

## Overview

Generalize lambda parameter types beyond the current hardcoded `i64`.
Currently, all lambda parameters are assumed to be 64-bit integers at both
the LLVM and Stone type system levels. This prevents passing record structs,
union pointers, strings, or booleans with correct types to lambdas.

Ask any questions up front, as much as possible. Once your questions have been answered, you may continue all the way to committing and wrap-up.

## Prerequisites

- **Lambdas** - `λ(x, y) { ... }` syntax and codegen (implemented)
- **Computed properties** - `Type@property := λ(self) { ... }` (implemented)
- **Type annotations** - `x :: Int` syntax (implemented)
- **Function type annotations** - `f :: (Int) -> Int` syntax (implemented)
- **Record types** - `Record(x :: Int, y :: Int)` (implemented)
- **Sum types** - `Null | Record(...)` (implemented)

## Goals

1. Lambda parameters should accept any Stone type, not just i64
2. Computed properties should work on record and union type receivers
3. The LLVM function signature should reflect actual parameter types
4. Stack allocation for parameters should match their LLVM type
5. The Stone type system (`Lambda#type`) should report actual param types
6. Existing behavior (integer/boolean lambdas) must not regress

## Motivation

The i64-only limitation blocks several downstream features:

```stone
# BROKEN: Computed property on a record type
Point := Record(x :: Int, y :: Int)
Point@magnitude := λ(self) { ... }
pt := Point(3, 4)
pt.magnitude  # Fails: struct passed to i64 parameter

# BROKEN: Computed property on a sum type
List :: (Type) -> Type
List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
IntList := List(Int)
List@empty? := λ(list) { list == NULL }
list := IntList(1, NULL)
list.empty?  # Fails: pointer passed to i64 parameter

# WORKS: Computed property on a primitive type
Int@abs := λ(self) { if(>(self, 0), { self }, { -(0, self) }) }
x := -42
x.abs  # Works: i64 passed to i64 parameter
```

## Current State

Three locations in `lib/stone/ast/lambda.rb` hardcode i64:

1. **LLVM function signature** (line 50-53):

    ```ruby
    private def param_types
      # For now, we assume all parameters are i64.
      [I64] * parameters.size
    end
    ```

2. **Stack allocation** (line 100-108):

    ```ruby
    private def argument_storage(func, builder)
      {}.tap do |storage|
        parameters.each_with_index do |param_name, i|
          alloca = builder.alloca(LLVM::Int64.type, param_name)
          builder.store(func.params[i], alloca)
          storage[param_name] = alloca
        end
      end
    end
    ```

3. **Stone type system** (line 34-37):

    ```ruby
    def type(context = nil)
      return_type = @block.type(context) || Stone::Type::Int
      param_types = parameters.map { Stone::Type::Int }
      Stone::Type.function(param_types:, return_type:)
    end
    ```

### How computed properties work today

1. `ComputedPropertyDefinition#to_llir` generates the lambda as a function and registers it as `"Type@property"` via `mod.register_function_alias`.

2. `PropertyAccess#handle_computed_property` looks up the function and calls it with the receiver value:

    ```ruby
    receiver_value = @receiver.to_llir(builder, mod, scope)
    builder.call(computed_func, receiver_value, "#{@property}_result")
    ```

3. The receiver value's LLVM type depends on the receiver:
    - `Int` -> `i64`
    - `Bool` -> `i1`
    - `String` -> `ptr` (pointer to string struct)
    - `Record` -> struct type (e.g., `{ i64, i64 }` for `Point(x :: Int, y :: Int)`)
    - Union pointer -> `ptr` (for heap-allocated union variants)

4. Since the lambda's function signature declares `i64` for all params, passing anything else causes an LLVM type mismatch or silent misinterpretation.

### How lambda parameters are accessed at runtime

`Reference#lookup_parameter` loads from the stack allocation created by `argument_storage`:

```ruby
private def lookup_parameter(builder, mod)
  param_storage = mod.lambda_param_storage
  return nil unless param_storage && param_storage[identifier]
  builder.load(param_storage[identifier], identifier)
end
```

The `builder.load` type is inferred from the alloca type, so fixing `argument_storage` to use correct types should propagate through `Reference` automatically.

## Design Decisions

### Decision 1: Lambda parameters get their types from type declarations

Lambda parameters are bare identifiers (`λ(x, y)`) with no inline type annotations.
Parameter types are determined from the existing `::` type declaration syntax:

```stone
# Type declaration provides parameter types for the lambda
Point@sum :: (Point) -> Int
Point@sum := λ(self) { self.x + self.y }

# The compiler matches positional parameter names to declared types:
#   self :: Point  (from the first param type in the declaration)

List@empty? :: (List) -> Bool
List@empty? := λ(list) { list == NULL }

# Standalone lambdas work the same way:
double :: (Int) -> Int
double := λ(x) { +(x, x) }

add :: (Int, Int) -> Int
add := λ(a, b) { +(a, b) }
```

**Fallback**: When no type declaration is present, parameters default to `i64`
(the current behavior). This preserves backward compatibility for existing code.
Type inference will be added later to handle cases without declarations.

**Flow**:

1. `f :: (Point) -> Int` registers a `FunctionTypeAnnotation` in the type registry
2. When `f := λ(self) { ... }` is compiled, the lambda looks up the registered
   type annotation for its name
3. The param types from the annotation (`[Point]` in this example) replace the default `[i64]`
4. The LLVM function signature, stack allocation, and Stone type all use the
   actual LLVM type for `Point`

The type declaration is already parsed and registered by
`TopFunction#register_function_types` and
`TwoPhaseProcessing#register_type_declarations`.

### Decision 2: Records are passed by value

Records are passed as LLVM structs by value (e.g., `{ i64, i64 }` for
`Point(x :: Int, y :: Int)`). This is simpler and matches how records already
flow through the system — `RecordInstantiation#to_llir` returns a struct value,
`PropertyAccess` extracts fields from struct values.

Recursive structures are not a concern for by-value passing because record
fields that reference other records or unions are stored as pointers (via
`compound_type_reference?` in `record_definition.rb`). So record structs are
always finite-size. The recursive chain lives in heap-allocated pointers,
not in the struct itself.

Stone type to LLVM calling convention:

- `Int` -> `i64` (by value)
- `Bool` -> `i1` (by value)
- `String` -> `ptr` (already a pointer)
- Record -> struct by value (e.g., `{ i64, i64 }`)
- Union/sum -> `ptr` (already heap-allocated)

### Decision 3: Return types are generalized in this same change

The return type is also hardcoded to `i64` currently. Since the type declaration
includes the return type and the Stone-type-to-LLVM-type mapping logic is
identical for params and returns, we generalize both in the same change. This
avoids touching the same files twice and enables computed properties that return
strings, records, or booleans.

### Decision 4: Booleans always use `i1`

Boolean parameters use `i1` (their natural LLVM type), regardless of whether a
type declaration is present. This is cleaner and type-correct. Existing
`Bool@flip` style lambdas that currently work by accident (boolean silently
widened to i64) will use the correct `i1` type.

## Test Cases

### Computed properties on records

```ruby
RSpec.describe "Lambda parameter types" do
  before do Stone::Scope.reset_top_level! end
  after do Stone::Scope.reset_top_level! end

  describe "computed properties on record types" do
    it "passes a record receiver to a computed property" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        Point@sum :: (Point) -> Int
        Point@sum := λ(self) { self.x + self.y }
        pt := Point(3, 4)
        pt.sum
      STONE
      expect(Stone.eval(code)).to eq(7)
    end

    it "works with single-field records" do
      code = <<~STONE
        Box := Record(value :: Int)
        Box@unwrap :: (Box) -> Int
        Box@unwrap := λ(self) { self.value }
        b := Box(42)
        b.unwrap
      STONE
      expect(Stone.eval(code)).to eq(42)
    end
  end
end
```

### Computed properties on sum types

```ruby
RSpec.describe "Lambda parameter types" do
  describe "computed properties on sum types" do
    it "passes a union value to a computed property" do
      code = <<~STONE
        List :: (Type) -> Type
        List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
        IntList := List(Int)
        List@empty? :: (List) -> Bool
        List@empty? := λ(list) { list == NULL }
        list := IntList(1, NULL)
        list.empty?
      STONE
      expect(Stone.eval(code)).to be false
    end

    it "returns TRUE for an empty list" do
      code = <<~STONE
        List :: (Type) -> Type
        List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
        IntList := List(Int)
        List@empty? :: (List) -> Bool
        List@empty? := λ(list) { list == NULL }
        empty := NULL
        empty.empty?
      STONE
      expect(Stone.eval(code)).to be true
    end
  end
end
```

### String parameter handling

```ruby
RSpec.describe "Lambda parameter types" do
  describe "string parameters" do
    it "passes a string to a lambda" do
      code = <<~STONE
        String@shout :: (String) -> String
        String@shout := λ(self) { self }
        s := "hello"
        s.shout
      STONE
      expect(Stone.eval(code)).to eq("hello")
    end
  end
end
```

### Standalone lambda with type declaration

```ruby
RSpec.describe "Lambda parameter types" do
  describe "standalone lambdas with type declarations" do
    it "uses parameter types from the type declaration" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        sum_fields :: (Point) -> Int
        sum_fields := λ(pt) { pt.x + pt.y }
        sum_fields(Point(10, 20))
      STONE
      expect(Stone.eval(code)).to eq(30)
    end
  end
end
```

### Existing primitive behavior preserved (no type declaration needed)

```ruby
RSpec.describe "Lambda parameter types" do
  describe "primitive parameters (regression)" do
    it "still works with integer parameters (no type declaration)" do
      code = <<~STONE
        Int@double := λ(self) { +(self, self) }
        x := 21
        x.double
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "still works with boolean parameters (no type declaration)" do
      code = <<~STONE
        Bool@flip := λ(self) { ¬(self) }
        t := TRUE
        t.flip
      STONE
      expect(Stone.eval(code)).to be false
    end

    it "still works with type declaration on primitives" do
      code = <<~STONE
        Int@triple :: (Int) -> Int
        Int@triple := λ(self) { +(self, +(self, self)) }
        x := 10
        x.triple
      STONE
      expect(Stone.eval(code)).to eq(30)
    end
  end
end
```

## Implementation Steps

### Step 0: Write tests

Follow TDD; write all the tests first.
Mark all the newly added tests as pending initially;
remove the pending flag as you attempt to pass each one.

### Step 1: Thread type declaration info to lambdas

When a lambda is assigned to a name that has a prior type declaration (e.g.,
`f :: (Point) -> Int` followed by `f := λ(self) { ... }`), look up the
registered `FunctionTypeAnnotation` and pass the declared parameter types
to the lambda before codegen. This already happens partially in
`TopFunction#register_function_types` — the type is registered in the registry
and scope, but the lambda's `to_llir` doesn't consult it.

### Step 2: Update `Lambda#param_types` to use actual LLVM types

Replace `[I64] * parameters.size` with actual LLVM types derived from the Stone types. Map Stone types to LLVM types:

- `Int` -> `i64`
- `Bool` -> `i1`
- `String` -> `ptr`
- Record types -> struct type or `ptr`
- Union types -> `ptr` (heap-allocated tagged unions)

### Step 3: Update `Lambda#argument_storage` to use actual types

Replace `builder.alloca(LLVM::Int64.type, param_name)` with the actual parameter type from the function signature.

### Step 4: Update `Lambda#type` for the Stone type system

Replace `parameters.map { Stone::Type::Int }` with actual Stone types.

### Step 5: Verify call sites pass correct types

Ensure `PropertyAccess#handle_computed_property` and any other call sites pass values whose LLVM types match the function signature.

### Step 6: Un-pend the sum type computed property tests

The 2 pending tests in `spec/language/types/sum_type_spec.rb` should now pass. Remove the `pending:` annotations.

## Files to Modify

1. `lib/stone/ast/lambda.rb` - `param_types`, `argument_storage`, `type`
2. `lib/stone/ast/computed_property_definition.rb` - Pass type context to lambda
3. `lib/stone/ast/property_access.rb` - Verify receiver values match expected types
4. `lib/stone/ast/reference.rb` - `lookup_parameter` may need type-aware load
5. `spec/language/types/sum_type_spec.rb` - Un-pend the 2 computed property tests

## Acceptance Criteria

- [ ] Computed properties work on record type receivers
- [ ] Computed properties work on sum type receivers (union pointers)
- [ ] Computed properties on `Int`, `Bool`, `String` still work (no regression)
- [ ] The 2 pending sum type tests pass and are un-pended
- [ ] Lambda LLVM function signatures reflect actual parameter types
- [ ] Lambda LLVM return types reflect actual declared return types
- [ ] Boolean parameters use `i1` (not widened to `i64`)
- [ ] `Lambda#type` returns actual Stone parameter and return types
- [ ] Lambdas without type declarations still default to `i64` params and return
- [ ] All existing tests pass
- [ ] `make test` passes
- [ ] `make lint` passes

## Gotchas and Challenges

### 1. Type information flow

Type declarations are registered in `TopFunction#register_function_types` before
codegen begins. The lambda needs to look up its declared type when it runs
`to_llir`. The challenge: a lambda doesn't inherently know its own name. The
name is assigned by `ConstantDefinition` or `ComputedPropertyDefinition`. Some
mechanism is needed to pass the declared name (or the resolved param types) to
the lambda before codegen — e.g., setting a `declared_param_types` attribute
on the lambda node, or passing declared types through `to_llir`.

### 2. Fallback to i64 when no type declaration exists

When no type declaration is present, all parameters default to `i64`. This
preserves backward compatibility for existing code like `Int@double := λ(self) { ... }`.
Type inference will be added later to handle undeclared cases automatically.

### 3. Union values are pointers or NULL

Sum type values (like `List(Int)`) are either heap-allocated pointers (for the
Record variant) or null pointers (for the Null variant). The lambda parameter
type should be `ptr` for union receivers, and the lambda body should handle
the null case.

### 4. Boolean regression risk

We're moving to have Booleans always use `i1`. Existing computed properties on Bool
(like `Bool@flip`) currently work because `i1` values passed to an `i64`
parameter get silently zero-extended. After this change, the function signature
will expect `i1`, which is correct — but verify that all existing Bool computed
property tests still pass.

### 5. `builder.load` type inference

`Reference#lookup_parameter` calls `builder.load(alloca, name)`. In LLVM, `load` infers the loaded type from the alloca's allocated type. If we fix `argument_storage` to use correct types, the load should automatically return the correct type. Verify this works for struct types.

## Relationship to Other Features

### Prerequisites

- Lambdas (implemented)
- Computed properties (implemented)
- Record types (implemented)
- Sum types (implemented)

### Enables

- **List type operations** - `List@empty?`, `List@length`, `List@map`, etc.
- **Sum type computed properties** - Properties on `Option`, `List`, `Result`, etc.
- **Record computed properties** - Properties on `Point`, `Pair`, etc.
- **Varargs** - Lambda bodies that operate on List parameters
- **Error types** - Functions that return and handle `T | Error`

### Future Enhancements

- **Type inference** - Infer parameter types when no declaration is present
- **Inline lambda parameter annotations** - `λ(self :: Point) { ... }` syntax
- **Higher-order functions** that accept typed lambda arguments

## Notes

- The key insight: type declarations (`f :: (Point) -> Int`) already exist and are registered in the type system — we just need to thread them through to `Lambda#param_types`
- The `FunctionTypeAnnotation` infrastructure exists and already computes Stone types — bridge it to lambda codegen by looking up the declared type when a lambda is assigned to a named constant or computed property
- When no type declaration exists, fall back to `i64` (current behavior). Type inference will be added later to eliminate the need for declarations in straightforward cases
- Avoid over-engineering: the minimal change is making `Lambda` consult the type registry for its declared param types, and mapping those Stone types to LLVM types

## Wrap-Up

Once you've completed the implementation:

- Update this file with any as-built changes we made to the design
    - Don't overwrite original design decisions
- Include this updated file as part of the commit
- Add any lessons learned to your "memory"
- Run the `/retro` command
