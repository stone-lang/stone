# Sum Types (Algebraic Data Types)

## Overview

Implement sum types (tagged unions / algebraic data types) in Stone by allowing `|` at the expression level to combine types. This enables defining types as a union of alternatives, where each alternative is an existing type (including `Null` and `Record` types).

Ask any questions up front, as much as possible. Once your questions have been answered, you may continue all the way to committing and wrap-up.

## Prerequisites

- **Union type annotations** — `|` in type annotations
- **Union type representation** — LLVM tagged union layout
- **Generic types** — `λ(T) { ... }` for parameterized types
- **Records** — `Record(field :: Type, ...)` definitions
- **NULL literal** — `Null` type with singleton `NULL` value
- **RTTI** — Runtime type constants and dispatch

## Goals

1. Allow `|` as an expression-level operator that takes two Type operands and returns a Type (the union)
2. Enable defining sum types: `Option := λ(T) { Null | Record(value :: T) }`
3. Enable recursive sum types: `List := λ(T) { Null | Record(first :: T, rest :: List(T)) }`
4. Reuse existing `Null` type (with singleton `NULL`) as the empty variant
5. Reuse existing `Record(...)` for variant data
6. Work with existing union type LLVM representation (tagged unions)
7. `Type.of()` works on sum type values to determine which variant they are

## Motivation

Sum types are foundational for functional programming. Without expression-level `|`, we can only use unions in type annotations, not define new types as unions:

```stone
# Currently works (type annotation):
x :: Int | Null

# Currently does NOT work (expression):
Option := λ(T) { Null | Record(value :: T) }
# Error: | is not a valid expression operator

# With sum types, we can define:
Option := λ(T) { Null | Record(value :: T) }
List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
Result := λ(T, E) { Record(value :: T) | Record(error :: E) }
Either := λ(A, B) { Record(left :: A) | Record(right :: B) }
```

## Design Decisions

### Decision 1: `|` is a type-level expression operator

`|` operates on values of type `Type` and returns a value of type `Type`. It is not valid on non-Type operands.

```stone
# Valid: both operands are Types
Null | Record(value :: Int)       # Returns a Type (the union)
Int | String                      # Returns a Type (the union)
Record(x :: Int) | Record(y :: String)  # Returns a Type

# Invalid: operands are not Types
3 | 5         # Type error: Int is not Type
"a" | "b"     # Type error: String is not Type
```

Since Stone does not yet have runtime type checking enforcement, the invalid cases may not produce errors immediately. But the semantics are clear: `|` is for types.

### Decision 2: Reuse existing `Null` and `Record`

No new variant/constructor syntax is needed. Sum types are built from existing primitives:

- `Null` — the zero-field "empty" variant (existing type)
- `Record(...)` — data-carrying variants (existing feature)

```stone
# Option type: Null or a value
Option := λ(T) { Null | Record(value :: T) }

# Constructing:
none := NULL                          # The Null variant
IntOption := Option(Int)
some := IntOption(42)                 # Constructs the Record variant
```

**Construction syntax**: Calling a sum type as a constructor delegates to the Record variant when arguments are provided. The empty variant is just `NULL`.

- Empty variant: `NULL`
- Data variant: Call the sum type (or its instantiation) with the Record's fields

```stone
List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
IntList := List(Int)

# Construction: calling IntList with Record-compatible args builds the Record variant
list := IntList(1, IntList(2, NULL))

# Empty list is just NULL
empty := NULL
```

This works because `IntList` resolves to the union type, and when called as a constructor with arguments matching the Record variant, it constructs that variant. When the value is `NULL`, it's the Null variant.

**Note on List definition style**: Previous prompts (`union-types.md`, `generic-types.md`) defined List with the union at the field level: `List := λ(T) { Record(first :: T, rest :: List(T) | Null) }`. The sum type approach moves the union to the top level: `List := λ(T) { Null | Record(first :: T, rest :: List(T)) }`. In the sum type version, `List(T)` is itself the union — a value is either `Null` or a `Record`. In the field-level version, a List is always a Record with a nullable `rest` field. The sum type version is the preferred approach going forward, as it properly models the empty list as a variant rather than relying on NULL in a field.

**Question**: How does the constructor dispatch work under the hood? When calling a sum type as a constructor, how does it know which variant to construct?

### Decision 3: Evaluation semantics

The expression `A | B` where A and B are Types:

1. Evaluates `A` to get a Type value
2. Evaluates `B` to get a Type value
3. Returns `Stone::Type.union(alternatives: [A, B])`

This reuses the existing `Stone::Type.union()` factory which handles flattening and deduplication.

### Decision 4: Associativity and precedence

Same as in type annotations:

- Left-associative: `A | B | C` means `(A | B) | C` (flattened to `A | B | C`)
- Lower precedence than function application: `Record(...) | Null` means `(Record(...)) | Null`
- Same flattening and deduplication as type annotation unions

## Current State

- `|` works in **type annotations** (after `::`) — parses to `UnionTypeAnnotation`
- `|` does **not** work in **expressions** — no grammar rule for it
- `Stone::Type.union()` factory exists and handles flattening/dedup
- Tagged union LLVM representation exists for record fields
- RTTI system supports union type constants
- `Type.of()` extracts runtime type tags from union values

## Desired State

```stone
# Define sum types using | at expression level
Option := λ(T) { Null | Record(value :: T) }
List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
Result := λ(T, E) { Record(value :: T) | Record(error :: E) }
Either := λ(A, B) { Record(left :: A) | Record(right :: B) }

# Instantiate
IntOption := Option(Int)
IntList := List(Int)

# Construct values
none := NULL
some := IntOption(42)                    # Constructs the Record variant

empty := NULL
list := IntList(1, IntList(2, NULL))     # Nested construction

# Inspect
Type.of(none).as_String    # "Null"
Type.of(some).as_String    # "Record(value :: Int)"  (or similar)

# Use
list.empty?                # FALSE (assuming List@empty? defined)
list.first                 # 1
list.rest.first            # 2
```

## Implementation Steps

### Step 0: Write tests

As always, we do TDD and write test cases before we start coding.

### Step 1: Add `|` to expression grammar

Add `|` as a binary operator in the expression grammar. It should have lower precedence than function application but be usable in expression contexts.

```ruby
# In lib/stone/grammar.rb
# Add a new rule for union expressions
rule(:union_expression) { 
  comparison_operation + (ws? + str("|") + ws? + comparison_operation)[1..] 
}

# Update expression to include union_expression
rule(:expression) { 
  type_declaration | union_expression | comparison_operation | boolean_operation 
}
```

The exact grammar integration will depend on the current expression hierarchy. The key requirement: `A | B` must parse when A and B are expressions, not just type terms.

**Important**: This must not conflict with the existing `type_union` rule used in type annotations. The `type_union` rule operates on `type_term` nodes (after `::`). The new expression-level `|` operates on general expressions.

### Step 2: Add AST node and transform

Create a `UnionExpression` AST node (distinct from `UnionTypeAnnotation`):

```ruby
# lib/stone/ast/union_expression.rb
module Stone
  class AST
    class UnionExpression < Stone::AST
      attr_reader :alternatives

      def initialize(alternatives)
        @alternatives = alternatives
        @name = :union_expression
      end
    end
  end
end
```

Add the corresponding transform rule to convert parsed `|` expressions into this AST node.

### Step 3: Implement LLVM codegen for UnionExpression

The `to_llir` method for `UnionExpression`:

1. Evaluate each alternative (should each produce a Type value)
2. Combine them using `Stone::Type.union()`
3. Return the resulting union Type

Since types are evaluated at compile time in Stone (type-level lambdas), this likely happens during lambda body evaluation when the lambda returns a type.

This step may require understanding how `Record(...)` currently produces a Type value in `to_llir` and following the same pattern.

### Step 4: Verify construction of sum type values

Ensure that when a sum type is instantiated:

- `NULL` produces a value of the Null variant
- Calling the type with Record-compatible arguments produces the Record variant
- The tagged union representation is used correctly
- We can have other primitive types as alternatives, such as `Int | String | Bool`.

This may already work if the type system correctly resolves the sum type to a union, and record instantiation handles union types.

### Step 5: Verify Type.of() and dispatch

Ensure:

- `Type.of(value)` correctly returns the runtime type for sum type values
- `value == NULL` correctly identifies the Null variant
- Property access (`.first`, `.rest`, etc.) works on the Record variant

### Step 6: Test with generic sum types

Verify that sum types work with generic type parameters:

```stone
List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
IntList := List(Int)
list := IntList(1, IntList(2, NULL))
list.first   # 1
```

This combines sum types with generic types and recursive types.

## Test Cases

### Basic Sum Type Definition

```ruby
RSpec.describe "Sum Types" do
  describe "expression-level union" do
    it "creates a union type from two types using |" do
      code = <<~STONE
        MyType := Int | String
        MyType
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end

    it "creates a union type from Null and a Record" do
      code = <<~STONE
        Option := Null | Record(value :: Int)
        Option
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end

    it "creates a multi-alternative union" do
      code = <<~STONE
        Triple := Int | String | Bool
        Triple
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end
  end
end
```

### Generic Sum Types

```ruby
RSpec.describe "Generic Sum Types" do
  it "defines a generic sum type" do
    code = <<~STONE
      Option :: (Type) -> Type
      Option := λ(T) { Null | Record(value :: T) }
      Option
    STONE
    expect { Stone.eval(code) }.not_to raise_error
  end

  it "instantiates a generic sum type" do
    code = <<~STONE
      Option :: (Type) -> Type
      Option := λ(T) { Null | Record(value :: T) }
      IntOption := Option(Int)
      IntOption
    STONE
    expect { Stone.eval(code) }.not_to raise_error
  end

  it "constructs the Record variant" do
    code = <<~STONE
      Option :: (Type) -> Type
      Option := λ(T) { Null | Record(value :: T) }
      IntOption := Option(Int)
      some := IntOption(42)
      some.value
    STONE
    expect(Stone.eval(code)).to eq(42)
  end

  it "uses NULL for the empty variant" do
    code = <<~STONE
      Option :: (Type) -> Type
      Option := λ(T) { Null | Record(value :: T) }
      IntOption := Option(Int)
      none := NULL
      none == NULL
    STONE
    expect(Stone.eval(code)).to be true
  end
end
```

### Recursive Sum Types

```ruby
RSpec.describe "Recursive Sum Types" do
  it "defines a recursive List type" do
    code = <<~STONE
      List :: (Type) -> Type
      List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
      IntList := List(Int)
      IntList
    STONE
    expect { Stone.eval(code) }.not_to raise_error
  end

  it "constructs a single-element list" do
    code = <<~STONE
      List :: (Type) -> Type
      List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
      IntList := List(Int)
      list := IntList(1, NULL)
      list.first
    STONE
    expect(Stone.eval(code)).to eq(1)
  end

  it "constructs a multi-element list" do
    code = <<~STONE
      List :: (Type) -> Type
      List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
      IntList := List(Int)
      list := IntList(1, IntList(2, IntList(3, NULL)))
      list.first
    STONE
    expect(Stone.eval(code)).to eq(1)
  end

  it "traverses a list via .rest" do
    code = <<~STONE
      List :: (Type) -> Type
      List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
      IntList := List(Int)
      list := IntList(1, IntList(2, IntList(3, NULL)))
      list.rest.rest.first
    STONE
    expect(Stone.eval(code)).to eq(3)
  end

  it "terminates with NULL" do
    code = <<~STONE
      List :: (Type) -> Type
      List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
      IntList := List(Int)
      list := IntList(1, NULL)
      list.rest == NULL
    STONE
    expect(Stone.eval(code)).to be true
  end
end
```

### Type.of() on Sum Type Values

```ruby
RSpec.describe "Type.of() on sum types" do
  it "returns Null for NULL variant" do
    code = <<~STONE
      List :: (Type) -> Type
      List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
      Type.of(NULL).as_String
    STONE
    expect(Stone.eval(code)).to eq("Null")
  end

  it "returns Record type for data variant" do
    code = <<~STONE
      List :: (Type) -> Type
      List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
      IntList := List(Int)
      list := IntList(42, NULL)
      Type.of(list).as_String
    STONE
    # Exact string TBD — may be the Record type name
    expect(Stone.eval(code)).not_to eq("Null")
  end
end
```

### Equality

```ruby
RSpec.describe "Sum type equality" do
  it "NULL equals NULL" do
    code = <<~STONE
      List :: (Type) -> Type
      List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
      NULL == NULL
    STONE
    expect(Stone.eval(code)).to be true
  end

  it "non-empty list does not equal NULL" do
    code = <<~STONE
      List :: (Type) -> Type
      List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
      IntList := List(Int)
      list := IntList(42, NULL)
      list == NULL
    STONE
    expect(Stone.eval(code)).to be false
  end
end
```

### Sum Types Without Generics

```ruby
RSpec.describe "Non-generic sum types" do
  it "defines a concrete sum type" do
    code = <<~STONE
      IntOption := Null | Record(value :: Int)
      IntOption
    STONE
    expect { Stone.eval(code) }.not_to raise_error
  end

  it "constructs a concrete sum type value" do
    code = <<~STONE
      IntOption := Null | Record(value :: Int)
      some := IntOption(42)
      some.value
    STONE
    expect(Stone.eval(code)).to eq(42)
  end
end
```

## Files to Create

1. `lib/stone/ast/union_expression.rb` — AST node for expression-level `|`
2. `spec/language/types/sum_type_spec.rb` — Integration tests

## Files to Modify

1. `lib/stone/grammar.rb` — Add `|` as expression-level operator
2. `lib/stone/transform.rb` — Transform `|` expressions to `UnionExpression` AST nodes
3. `lib/stone/ast/lambda.rb` — Ensure type-level lambdas can return union expressions
4. Possibly `lib/stone/ast/record_instantiation.rb` — Handle instantiation of union types
5. Possibly `lib/stone/type.rb` — Any adjustments for expression-level union creation

## Acceptance Criteria

- [ ] `Int | String` as an expression evaluates to a union Type
- [ ] `Int | String | Bool` (multi-alternative) works
- [ ] `Null | Record(value :: Int)` defines a sum type
- [ ] `λ(T) { Null | Record(value :: T) }` defines a generic sum type
- [ ] Recursive sum types work: `λ(T) { Null | Record(first :: T, rest :: List(T)) }`
- [ ] `NULL` serves as the Null variant value
- [ ] Record variant can be constructed via type instantiation (e.g., `IntOption(42)`)
- [ ] `Type.of()` distinguishes variants at runtime
- [ ] `value == NULL` correctly tests for Null variant
- [ ] Property access works on Record variant values (e.g., `.value`, `.first`)
- [ ] Methods can be defined on sum types (e.g., `List@empty?`)
- [ ] Existing tagged union LLVM representation is reused (no new runtime representation)
- [ ] Existing union type annotation tests still pass
- [ ] All existing tests pass
- [ ] `make test` passes
- [ ] `make lint` passes

## Gotchas and Challenges

### 1. Grammar Ambiguity with Type Annotations

The `|` operator already exists in type annotations (after `::`). The new expression-level `|` must not interfere. The parser must distinguish:

```stone
x :: Int | String        # Type annotation union (existing)
MyType := Int | String   # Expression union (new)
```

The distinction is contextual: after `::` it's a type annotation; otherwise it's an expression. The existing `type_union` rule only triggers inside `type_annotation`, so a new expression-level rule should be safe.

### 2. Construction of Union Type Values

When `MyType := Null | Record(value :: Int)`, how does `MyType(42)` work? The union type has a Record alternative with a `value` field. Calling the union type as a constructor should delegate to the Record variant when arguments are provided.

This may require special handling in record/type instantiation to check if the target type is a union and find the matching Record alternative.

### 3. Type-Level vs. Value-Level Evaluation

`Null | Record(...)` must evaluate at compile time (producing a Type), not at runtime. This is consistent with how `Record(...)` already works — it defines a type, not a value.

The `|` operator in expression context must detect that its operands are Types and produce a Type result.

### 4. Interaction with Generic Types

```stone
List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
```

The lambda body `Null | Record(first :: T, rest :: List(T))` must:

1. Resolve `T` from the lambda parameter
2. Evaluate `Record(first :: T, rest :: List(T))` as a type
3. Combine `Null` and the Record type via `|`
4. Return the union type

This is compile-time evaluation within a type-level lambda.

### 5. Named vs. Anonymous Record Variants

With `Null | Record(first :: T, rest :: List(T))`, the Record is anonymous. This means:

- `Type.of()` on a list node returns an anonymous Record type
- There's no named constructor like `Cons`

This is acceptable for now. Named variants (e.g., `Some`, `None`, `Cons`) could be added later as sugar.

## Opportunities

### 1. Option/Maybe Type

```stone
Option := λ(T) { Null | Record(value :: T) }
# Enables safe nullable types
```

### 2. Result/Either Type

```stone
Result := λ(T, E) { Record(value :: T) | Record(error :: E) }
# Enables typed error handling
```

### 3. Tree Types

```stone
Tree := λ(T) { Null | Record(value :: T, left :: Tree(T), right :: Tree(T)) }
```

### 4. Future: Named Variants

```stone
# Potential future syntax with named constructors:
Color := Red | Green | Blue
Shape := Circle(radius :: Int) | Rectangle(width :: Int, height :: Int)
```

This would require additional syntax beyond what this prompt implements.

### 5. Future: Pattern Matching

```stone
match(list):
  | NULL -> 0
  | Record(first, rest) -> 1 + length(rest)
```

## Relationship to Other Features

### Prerequisites

- **Union type annotations** — Parsing `|` in type contexts
- **Union type representation** — LLVM tagged union storage
- **Generic types** — Parameterized type definitions
- **Records** — Data-carrying variants
- **RTTI** — Runtime type dispatch

### Enables

- **List type** (`docs/prompts/list-type.md`) — `List := λ(T) { Null | Record(first :: T, rest :: List(T)) }`
- **Option type** — Safe nullable types
- **Result type** — Typed error handling
- **Tree types** — Binary trees, ASTs

### Future Enhancements

- **Named variants** — `Some(value :: T)` instead of `Record(value :: T)`
- **Pattern matching** — Destructuring on variant types
- **Exhaustiveness checking** — Compiler verifies all cases handled
- **Enum types** — `Color := Red | Green | Blue` (zero-field variants with distinct identities)

## Notes

- The key insight is that `|` on Types produces a Type — it's a type combinator, not a value operator
- No new runtime representation is needed — reuse existing tagged union infrastructure
- No new type concepts — union types already exist; we're just allowing them in expressions
- Construction piggybacks on existing Record instantiation
- The scope of this prompt is narrow: add `|` to expressions, verify it works with existing infrastructure
- Avoid over-engineering: don't add named variants, pattern matching, or exhaustiveness yet

## Open Questions

- Can we unify the `|` operator implementation for both type annotations and expressions to reduce duplication?
- Are there any edge cases in construction or type resolution we haven't considered?
- Do we need to adjust error messages for union type construction failures?

## Related Reading

- Existing Stone prompt: `docs/prompts/union-types.md` — Union type annotations
- Existing Stone prompt: `docs/prompts/union-type-representation.md` — LLVM representation
- Existing Stone prompt: `docs/prompts/generic-types.md` — Generic type definitions
- [OCaml Algebraic Data Types](https://ocaml.org/docs/basic-data-types)
- [Haskell Data Declarations](https://www.haskell.org/tutorial/goodies.html)
- [Rust Enums](https://doc.rust-lang.org/book/ch06-01-defining-an-enum.html)

## As-Built Changes

### Constructor Dispatch

The user chose approach (b): match by argument types/count. Currently dispatches to the first Record alternative whose field count matches the argument count. A NOTE comment acknowledges same-arity ambiguity as a future improvement.

### Whitespace Around `|`

The user confirmed whitespace around `|` should be optional. Grammar uses `ws?` on both sides.

### Files Created (not in original plan)

- `lib/stone/ast/union_type_registration.rb` -- Shared module extracted during code review to eliminate duplication of type registration logic across `ConstantDefinition`, `FunctionCall`, and `TopFunction`.

### Files Modified (beyond original plan)

- `lib/stone/ast/record_definition.rb` -- `record_reference?` renamed to `compound_type_reference?` to handle union type references in record field LLVM type resolution.
- `lib/stone/ast/record_instantiation.rb` -- Updated `field_expects_pointer?` to include union types.
- `lib/stone/ast/reference.rb` -- `lookup_generic_type` now returns dummy value for union types too.
- `spec/unit/type/generic_spec.rb` -- Updated to use `body_template` (renamed from `record_template`).

### Key Implementation Details

1. **Record naming within unions**: Anonymous Record alternatives get names like `"UnionName$Index"` (e.g., `"IntOption$0"`).
2. **Two-phase registration**: Placeholder union registered first (with `[Null]` alternatives), then real types resolved. Essential for recursive types like `List(T)`.
3. **`generic_base_name`**: Added to `Stone::Type::Union` to enable computed property fallback. Extracted from canonical name (e.g., `"List"` from `"List(Int)"`). The fallback infrastructure is implemented, but computed property tests are pending because Stone's lambda infrastructure assumes all parameters are i64 -- passing record structs or union pointers requires lambda parameter type generalization.
4. **Scope type vs module registration**: For union constructor calls, the record instance is registered in the module (for field access) but the union type is declared in scope (for computed property lookup).
5. **`UnionExpression#to_llir`**: Returns a dummy `LLVM::Int64.from_i(0)`. The real work happens during type registration phases, not during LLIR generation.

### Acceptance Criteria Status

- [x] `Int | String` as an expression evaluates to a union Type
- [x] `Int | String | Bool` (multi-alternative) works
- [x] `Null | Record(value :: Int)` defines a sum type
- [x] `λ(T) { Null | Record(value :: T) }` defines a generic sum type
- [x] Recursive sum types work: `λ(T) { Null | Record(first :: T, rest :: List(T)) }`
- [x] `NULL` serves as the Null variant value
- [x] Record variant can be constructed via type instantiation (e.g., `IntOption(42)`)
- [x] `Type.of()` distinguishes variants at runtime
- [x] `value == NULL` correctly tests for Null variant
- [x] Property access works on Record variant values (e.g., `.value`, `.first`)
- [ ] Methods can be defined on sum types (e.g., `List@empty?`) -- infrastructure ready, blocked by lambda param type limitation
- [x] Existing tagged union LLVM representation is reused (no new runtime representation)
- [x] Existing union type annotation tests still pass
- [x] All existing tests pass
- [x] `make test` passes (1057 examples, 0 failures, 2 pending)
- [x] `make lint` passes (134 files, 0 offenses)

### Known Limitations

1. **Same-arity ambiguity**: If a union has multiple Record alternatives with the same number of fields, the first one is selected. Future improvement: use type checking to disambiguate.
2. **Lambda parameter types**: Stone's lambda infrastructure assumes all parameters are i64. Computed properties on sum types require passing struct/pointer values, which needs lambda parameter type generalization.

## Wrap-Up

Once you've completed the implementation:

- Update this file with any as-built changes we made to the design
    - Don't overwrite original design decisions
- Include this updated file as part of the commit
- Add any lessons learned to your "memory"
- Run the `/retro` command
