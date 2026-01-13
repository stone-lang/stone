# Union Types

## Overview

Implement union types in Stone's type annotations, allowing a value to be one of several types. The syntax `TypeA | TypeB` indicates a value can be either TypeA or TypeB. This is essential for properly typing nullable fields, error handling, and algebraic data types.

## Prerequisites

- Basic type annotations work (`x :: Int`)
- Type annotation scoping (type references resolve from scope)
- NULL literal implemented
- Function type syntax (for union types in function signatures)

## Goals

1. Parse union types in type annotations: `Int | String`
2. Support multiple alternatives: `Int | String | Bool`
3. Support union with NULL: `List(T) | NULL`
4. Support union types in record fields: `value :: Int | NULL`
5. Support union types in function signatures: `(Int) -> (String | NULL)`
6. Runtime representation preserves type information (tagged union)

## Implementation Scope (Clarified)

**Phase 1 (current implementation):**

- Parsing + AST + type annotation storage
- `compatible_with?` method on `Stone::Type` class (for future type checking)
- `Stone::Type.union(alternatives:)` factory method
- No runtime type enforcement (union types are for static analysis)
- `Type.of()` returns the **actual runtime type** of the value, not the declared union type

**Deferred:**

- Runtime type checking/enforcement
- Tagged union LLVM representation (not needed until pattern matching)
- Type-level lambdas in unions (untested, may or may not work)

**Prerequisite status (verified):**

- NULL comparison works: `NULL == NULL`, `NULL == 42`, `42 == NULL` all work
- Conditionals work with Int comparisons: `if(x > 0, {...}, {...})`
- Function type syntax fully implemented

## Motivation

Without union types, we must special-case NULL compatibility. With union types:

```stone
# Explicit nullability
IntList := Record(first :: Int, rest :: IntList | NULL)

# Result type for error handling
Result := Record(value :: Int | NULL, error :: String | NULL)

# Flexible function return
parseNumber :: (String) -> (Int | NULL)
```

## Design Decisions

### Syntax: Pipe Operator

Use `|` for union types (common in TypeScript, Python, etc.):

```stone
x :: Int | String     # x is Int or String
y :: A | B | C        # y is A, B, or C
z :: List(T) | NULL   # z is List(T) or NULL
```

### Associativity and Precedence

- Union is left-associative: `A | B | C` means `(A | B) | C`
- Lower precedence than type application: `List(T) | NULL` means `(List(T)) | NULL`
- Lower precedence than function arrow: `(Int) -> Int | NULL` means `(Int) -> (Int | NULL)`

### Flattening

Nested unions are flattened:

- `(A | B) | C` equals `A | B | C`
- `A | (B | C)` equals `A | B | C`

### Deduplication

Duplicate types are removed:

- `Int | Int` equals `Int`
- `Int | String | Int` equals `Int | String`

### Runtime Representation

Options for representing union values at runtime:

#### Option A: Tagged unions (recommended)

Each value carries a type tag indicating which variant it is:

```llvm
%union = type { i8, i64 }  ; { tag, value }
; tag 0 = first type, tag 1 = second type, etc.
```

#### Option B: Untagged (unsafe)

Just use the largest type's representation. Requires careful handling.

**Recommendation**: Use Option A (tagged unions) for safety, with optimization possible when one variant is NULL (tag not needed since 0 is distinguishable).

### Special Case: Nullable Types

`T | NULL` is common enough to optimize:

- NULL is represented as 0
- Non-null T is a non-zero pointer or value
- No explicit tag needed (NULL is distinguishable)

## Implementation Steps

### Step 1: Update Grammar

```ruby
# In lib/stone/grammar.rb
rule(:type_annotation) { type_union }
rule(:type_union) { type_term + (ws? + str("|") + ws? + type_term)[0..] }
rule(:type_term) { type_function | type_application | type_name }
```

### Step 2: Create UnionType AST Node

```ruby
# lib/stone/ast/union_type.rb
module Stone
  class AST
    class UnionType < Stone::AST
      attr_reader :alternatives

      def initialize(alternatives)
        @alternatives = flatten_and_dedupe(alternatives)
        @name = :union_type
      end

      def to_s
        @alternatives.map(&:to_s).join(" | ")
      end

      def resolve(scope)
        resolved = @alternatives.map { |t| t.resolve(scope) }
        Stone::Type::Union.new(resolved)
      end

      private def flatten_and_dedupe(types)
        flattened = types.flat_map do |t|
          t.is_a?(UnionType) ? t.alternatives : [t]
        end
        flattened.uniq
      end
    end
  end
end
```

### Step 3: Create Union Type Class

```ruby
# lib/stone/type/union.rb
module Stone
  module Type
    class Union < Base
      attr_reader :alternatives

      def initialize(alternatives)
        @alternatives = flatten_and_dedupe(alternatives)
      end

      def name
        @alternatives.map(&:name).join(" | ")
      end

      def nullable?
        @alternatives.any? { |t| t == Null }
      end

      def non_null_type
        remaining = @alternatives.reject { |t| t == Null }
        remaining.length == 1 ? remaining.first : Union.new(remaining)
      end

      def llvm_type
        if nullable? && @alternatives.length == 2
          # Optimize nullable: just use the non-null type's representation
          non_null_type.llvm_type
        else
          # Tagged union: { i8 tag, i64 value }
          LLVM::Type.struct([LLVM::Int8, LLVM::Int64], false)
        end
      end

      def compatible_with?(other)
        case other
        when Union
          # All our alternatives must be compatible with some alternative in other
          @alternatives.all? { |t| other.alternatives.any? { |o| t.compatible_with?(o) } }
        else
          # Single type is compatible if it matches any alternative
          @alternatives.any? { |t| t.compatible_with?(other) }
        end
      end

      def ==(other)
        other.is_a?(Union) && 
          Set.new(@alternatives) == Set.new(other.alternatives)
      end

      private def flatten_and_dedupe(types)
        flattened = types.flat_map do |t|
          t.is_a?(Union) ? t.alternatives : [t]
        end
        flattened.uniq
      end
    end
  end
end
```

### Step 4: Update Transform

```ruby
# In lib/stone/transform.rb
transform(:type_union) do |node|
  # Collect all type_term children
  type_terms = node.children.select { |c| 
    c.respond_to?(:name) && c.name == :type_term 
  }
  
  alternatives = type_terms.map { |t| transform(t) }
  
  if alternatives.length == 1
    alternatives.first  # Not a union, just the single type
  else
    Stone::AST::UnionType.new(alternatives)
  end
end
```

### Step 5: Update Type Checking

```ruby
# Add to type checking logic
def types_compatible?(expected, actual)
  return true if expected == actual
  return true if actual == Stone::Type::Null && expected.is_a?(Stone::Type::Union) && expected.nullable?
  
  if expected.is_a?(Stone::Type::Union)
    expected.alternatives.any? { |t| types_compatible?(t, actual) }
  else
    false
  end
end
```

### Step 6: Runtime Value Construction

```ruby
# When creating a value that should be a union type:
def wrap_in_union(builder, value, value_type, union_type)
  if union_type.nullable? && union_type.alternatives.length == 2
    # Optimized nullable - no wrapping needed
    value
  else
    # Tagged union
    tag_index = union_type.alternatives.index(value_type)
    struct = union_type.llvm_type.null
    struct = builder.insert_value(struct, LLVM::Int8.from_i(tag_index), 0)
    struct = builder.insert_value(struct, value, 1)
    struct
  end
end
```

## Test Cases

```ruby
RSpec.describe "Union Types" do
  describe "parsing" do
    it "parses simple union type" do
      code = <<~STONE
        x :: Int | String
        x := 42
        x
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "parses multi-alternative union" do
      code = <<~STONE
        x :: Int | String | Bool
        x := TRUE
        x
      STONE
      expect(Stone.eval(code)).to be true
    end

    it "parses nullable type" do
      code = <<~STONE
        x :: Int | NULL
        x := NULL
        x == NULL
      STONE
      expect(Stone.eval(code)).to be true
    end
  end

  describe "in record fields" do
    it "allows nullable field" do
      code = <<~STONE
        Box := Record(value :: Int | NULL)
        b := Box(NULL)
        b.value == NULL
      STONE
      expect(Stone.eval(code)).to be true
    end

    it "allows non-null value in nullable field" do
      code = <<~STONE
        Box := Record(value :: Int | NULL)
        b := Box(42)
        b.value
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "allows recursive type with NULL" do
      code = <<~STONE
        IntList := Record(first :: Int, rest :: IntList | NULL)
        list := IntList(1, IntList(2, NULL))
        list.rest.first
      STONE
      expect(Stone.eval(code)).to eq(2)
    end
  end

  describe "in function signatures" do
    it "allows union return type" do
      code = <<~STONE
        maybeDouble :: (Int) -> (Int | NULL)
        maybeDouble := λ(x) { if(x > 0, { x * 2 }, { NULL }) }
        maybeDouble(21)
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "allows union parameter type" do
      code = <<~STONE
        process :: (Int | NULL) -> Int
        process := λ(x) { if(x == NULL, { 0 }, { x }) }
        process(42)
      STONE
      expect(Stone.eval(code)).to eq(42)
    end
  end

  describe "type application in unions" do
    it "parses List(T) | NULL" do
      code = <<~STONE
        List :: Type -> Type
        List := λ(T) { Record(first :: T, rest :: List(T) | NULL) }
        IntList := List(Int)
        list := IntList(1, NULL)
        list.first
      STONE
      expect(Stone.eval(code)).to eq(1)
    end
  end

  describe "flattening and deduplication" do
    it "flattens nested unions" do
      code = <<~STONE
        x :: (Int | String) | Bool
        x := TRUE
        x
      STONE
      expect(Stone.eval(code)).to be true
    end

    it "deduplicates types" do
      code = <<~STONE
        x :: Int | Int
        x := 42
        x
      STONE
      expect(Stone.eval(code)).to eq(42)
    end
  end
end
```

## Files to Create

1. `lib/stone/ast/union_type.rb` - AST node for union types
2. `lib/stone/type/union.rb` - Union type class
3. `spec/language/types/union_type_spec.rb` - Integration tests
4. `spec/unit/type/union_spec.rb` - Unit tests

## Files to Modify

1. `lib/stone/grammar.rb` - Union type syntax (may already be partially done)
2. `lib/stone/transform.rb` - Transform union type nodes
3. `lib/stone/types.rb` - Require union type
4. `lib/stone/ast/record_definition.rb` - Handle union types in field resolution

## Acceptance Criteria

- [ ] `Int | String` parses as a union type
- [ ] `A | B | C` parses as multi-alternative union
- [ ] `T | NULL` is recognized as nullable
- [ ] Union types work in record field annotations
- [ ] Union types work in function signatures
- [ ] `List(T) | NULL` works (type application in union)
- [ ] Nested unions are flattened
- [ ] Duplicate types are removed
- [ ] NULL is compatible with any `T | NULL` type
- [ ] All existing tests pass
- [ ] `make test` passes
- [ ] `make lint` passes

## Relationship to Other Features

### Prerequisites

- Type annotations
- Type annotation scoping
- NULL literal
- Function type syntax

### Enables

- Proper nullable types (removing NULL special-case)
- Error handling patterns (Result types)
- Algebraic data types
- Pattern matching (future)
- **Arithmetic error handling**: Return `Int | Error.Overflow` instead of halting
    - See `docs/prompts/arithmetic-operators.md`
    - Currently arithmetic errors halt execution; union types enable proper error returns

### Future Enhancements

- Pattern matching on union types
- Type narrowing after checks: `if(x != NULL, { x.foo }, ...)`
- Exhaustiveness checking
- Tagged union syntax sugar: `enum Color { Red | Green | Blue }`

## Notes

- Union types are primarily for type checking, not runtime dispatch
- The nullable optimization (`T | NULL`) avoids runtime overhead for common case
- Without pattern matching, accessing union values requires care
- This removes the need to special-case NULL compatibility
- Consider adding a `Nullable(T)` type alias for `T | NULL`

