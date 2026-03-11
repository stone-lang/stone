# NULL Literal

## Overview

Implement NULL as a literal value in Stone. NULL is the single value of the Null type and is special-cased to be compatible with any type. This enables representing "no value" or "end of list" in recursive data structures.

## Prerequisites

- Basic literal support (Int, Bool, String already work)

## Goals

1. Add NULL as a recognized literal in the grammar
2. Create NullLiteral AST node
3. NULL compiles to LLVM i64 value 0
4. NULL is compatible with any type (special-cased, not a proper bottom type)
5. NULL can be compared with `==` and `!=`

## Design Decisions

### NULL as Special Value (not Bottom Type)

For simplicity, NULL is special-cased to be allowed anywhere regardless of type. This is NOT a proper bottom type implementation - it's a pragmatic choice to enable recursive data structures before we have union types.

Future work: Replace with proper union types like `List(T) | NULL`.

### Representation

NULL is represented as i64 value 0 at the LLVM level. This is compatible with:

- Null pointers (pointer value 0)
- Record fields that store pointers as i64
- Comparison operations

## Implementation Steps

### Step 1: Update Grammar

Add NULL to the literal rule:

```ruby
# In lib/stone/grammar.rb
rule(:literal) { literal_null | literal_boolean | literal_string | literal_i64 }
rule(:literal_null) { str("NULL") }
```

### Step 2: Create NullLiteral AST Node

```ruby
# lib/stone/ast/null_literal.rb
module Stone
  class AST
    class NullLiteral < Stone::AST::Expression

      def initialize
        @name = :null_literal
      end

      def to_llir(_builder, _mod)
        # NULL is represented as 0 (null pointer as i64)
        LLVM::Int64.from_i(0)
      end

      def to_s
        "NULL"
      end

      def type(_context = nil)
        Stone::Type::Null
      end

    end
  end
end
```

### Step 3: Create Null Type

```ruby
# lib/stone/type/null.rb
module Stone
  module Type
    class NullType < Base
      def name
        "Null"
      end

      def llvm_type
        LLVM::Int64
      end

      # NULL is compatible with any type (special case)
      def compatible_with?(_other_type)
        true
      end
    end

    Null = NullType.new
  end
end
```

### Step 4: Update Transform

```ruby
# In lib/stone/transform.rb
require "stone/ast/null_literal"

transform(:literal_null) do |_node|
  Stone::AST::NullLiteral.new
end
```

### Step 5: Update Equality Comparisons

Ensure `==` and `!=` work with NULL:

```ruby
# In comparison handling, NULL comparison should work:
# - NULL == NULL → TRUE
# - value == NULL → FALSE (unless value is NULL)
# - NULL == value → FALSE (unless value is NULL)
```

## Test Cases

```ruby
RSpec.describe "NULL literal" do
  describe "basic usage" do
    it "NULL is a valid expression" do
      expect { Stone.eval("NULL") }.not_to raise_error
    end

    it "NULL can be assigned to a constant" do
      code = <<~STONE
        x := NULL
        x
      STONE
      expect(Stone.eval(code)).to eq(0)  # Returns 0 at LLVM level
    end
  end

  describe "equality" do
    it "NULL equals NULL" do
      expect(Stone.eval("NULL == NULL")).to be true
    end

    it "NULL does not equal an integer" do
      expect(Stone.eval("NULL == 42")).to be false
    end

    it "integer does not equal NULL" do
      expect(Stone.eval("42 == NULL")).to be false
    end

    it "NULL != 42 is true" do
      expect(Stone.eval("NULL != 42")).to be true
    end
  end

  describe "use in records" do
    it "can be used as a record field value" do
      code = <<~STONE
        Box := Record(value :: Int)
        b := Box(NULL)
        b.value == NULL
      STONE
      expect(Stone.eval(code)).to be true
    end
  end
end
```

## Files to Create

1. `lib/stone/ast/null_literal.rb` - AST node
2. `lib/stone/type/null.rb` - Null type
3. `spec/language/literals/Null/null_literals_spec.rb` - Tests

## Files to Modify

1. `lib/stone/grammar.rb` - Add literal_null rule
2. `lib/stone/transform.rb` - Add transform for literal_null
3. `lib/stone/types.rb` - Require null type

## Acceptance Criteria

- [ ] `NULL` parses as a literal
- [ ] `NULL` compiles to LLVM i64 value 0
- [ ] `NULL == NULL` returns TRUE
- [ ] `NULL == 42` returns FALSE
- [ ] `42 == NULL` returns FALSE
- [ ] NULL can be used as a record field value
- [ ] All existing tests pass
- [ ] `make test` passes
- [ ] `make lint` passes

## Notes

- NULL is intentionally simple - just the value 0
- Type compatibility is special-cased, not a proper type system feature
- This is a stepping stone toward union types like `T | NULL`
- For FFI, NULL being 0 is standard and compatible with C null pointers
