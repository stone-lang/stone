# Function Type Syntax

## Overview

Implement function type syntax in Stone's type annotations, using `(A) -> B` notation. This enables expressing the types of lambdas and higher-order functions, which is essential for generics and type-level programming.

## Prerequisites

- Basic type annotations work (`x :: Int`)
- Type declaration tracking (`type-declaration-tracking.md`) - type declarations stored in registry

## Goals

1. Parse function types in type annotations: `(A) -> B`
2. Support nested function types with explicit parentheses: `(A) -> ((B) -> C)`
3. Support multiple parameters: `(A, B) -> C`
4. Support zero parameters: `() -> A`
5. Function types can be used in signatures: `double :: (Int) -> Int`
6. Function types can be used in record field declarations

## Design Decisions

### No Currying in Type Signatures

Type signatures mirror the actual lambda structure. A curried function:

```stone
add := λ(x) { λ(y) { x + y } }
```

Has the type signature:

```stone
add :: (Int) -> ((Int) -> Int)
```

NOT `(Int, Int) -> Int`. The parentheses in the type correspond to the parentheses in the lambda.

### Parentheses Required Around Parameters

For clarity and unambiguous parsing:

- `(Int) -> Int` ✓
- `Int -> Int` ✗ (ambiguous with subtraction)
- `(Int, String) -> Bool` ✓
- `() -> Int` ✓ (zero parameters)

### Explicit Parentheses Required for Nested Function Types

Multiple arrows require explicit parentheses. There is NO implicit associativity:

- `(A) -> ((B) -> C)` ✓ (explicit nesting)
- `((A) -> B) -> C` ✓ (explicit nesting)
- `(A) -> (B) -> C` ✗ (parse error - ambiguous)

This forces clarity and avoids confusion about function type structure.

### No Union Types or Type Application (Yet)

This prompt focuses only on function types. The following are deferred:

- Union types (`Int | String`) - see `union-types.md`
- Type application (`List(Int)`) - see `generic-types.md`

## Syntax

```text
type_annotation := type_function | type_name
type_function   := type_params "->" type_return
type_params     := "(" comma_separated(type_annotation) ")"
type_return     := type_name | "(" type_function ")"
type_name       := identifier
```

Key points:

- Function type requires parenthesized parameters: `(Int) -> Int`
- Return type is either a simple name OR a parenthesized function type
- This prevents `(A) -> (B) -> C` from parsing (must be `(A) -> ((B) -> C)`)

## Implementation Steps

### Step 1: Update Grammar

```ruby
# In lib/stone/grammar.rb
rule(:type_annotation) { type_function | type_name }
rule(:type_function) { type_params + ws? + str("->") + ws? + type_return }
rule(:type_params) { parens(comma_separated(type_annotation, allow_trailing: false)[0..]) }
rule(:type_return) { type_name | parens(type_function) }
rule(:type_name) { identifier }
```

Note: `type_return` allows either a simple identifier OR a parenthesized function type, but NOT an unparenthesized function type. This enforces explicit nesting.

### Step 2: Create FunctionTypeAnnotation AST Node

```ruby
# lib/stone/ast/function_type_annotation.rb
module Stone
  class AST
    class FunctionTypeAnnotation < Stone::AST
      attr_reader :param_types, :return_type

      def initialize(param_types, return_type)
        @param_types = param_types   # Array of type annotation AST nodes
        @return_type = return_type   # Type annotation AST node
        @name = :function_type_annotation
      end

      def to_s
        params = @param_types.map(&:to_s).join(", ")
        "(#{params}) -> #{@return_type}"
      end

      # Convert to Stone::Type for type checking
      def to_type(registry)
        param_stone_types = @param_types.map { |t| t.to_type(registry) }
        return_stone_type = @return_type.to_type(registry)
        Stone::Type.function(param_types: param_stone_types, return_type: return_stone_type)
      end
    end
  end
end
```

### Step 3: Update TypeAnnotation AST Node

```ruby
# lib/stone/ast/type_annotation.rb
module Stone
  class AST
    class TypeAnnotation < Stone::AST
      attr_reader :type_name

      def initialize(type_name)
        @type_name = type_name
        @name = :type_annotation
      end

      def to_s
        type_name
      end

      # Convert to Stone::Type for type checking
      def to_type(registry)
        registry.lookup(type_name)
      end
    end
  end
end
```

### Step 4: Update Transform

```ruby
# In lib/stone/transform.rb
require "stone/ast/function_type_annotation"

transform(:type_annotation) do |node|
  # Check if this is a function type or simple type name
  type_function_node = node.find_child(:type_function)
  if type_function_node
    transform(type_function_node)
  else
    type_name_node = node.find_child(:type_name)
    type_name = extract_identifier_text(type_name_node)
    Stone::AST::TypeAnnotation.new(type_name)
  end
end

transform(:type_function) do |node|
  params_node = node.find_child(:type_params)
  return_node = node.find_child(:type_return)

  param_types = extract_type_annotations(params_node)
  return_type = transform_return_type(return_node)

  Stone::AST::FunctionTypeAnnotation.new(param_types, return_type)
end

transform(:type_return) do |node|
  # type_return is either type_name or parens(type_function)
  type_name_node = node.find_child(:type_name)
  if type_name_node
    type_name = extract_identifier_text(type_name_node)
    Stone::AST::TypeAnnotation.new(type_name)
  else
    type_function_node = node.find_child(:type_function)
    transform(type_function_node)
  end
end

private def extract_type_annotations(params_node)
  return [] unless params_node

  params_node.children
    .select { |c| c.respond_to?(:name) && c.name == :type_annotation }
    .map { |c| transform(c) }
end

private def transform_return_type(return_node)
  return nil unless return_node
  transform(return_node)
end
```

### Step 5: Update TypeDeclaration to Handle Complex Annotations

```ruby
# In lib/stone/ast/type_declaration.rb
class TypeDeclaration < Stone::AST
  attr_reader :identifier, :type_annotation

  def initialize(identifier, type_annotation)
    @identifier = identifier
    @type_annotation = type_annotation  # Now can be TypeAnnotation or FunctionTypeAnnotation
    @name = :type_declaration
  end

  def to_llir(_builder, mod)
    mod.register_type_declaration(identifier, type_annotation)
    nil
  end

  def to_s
    "#{identifier} :: #{type_annotation}"
  end
end
```

## Test Cases

```ruby
RSpec.describe "Function Type Syntax" do
  describe "parsing function types" do
    it "parses simple function type in signature" do
      code = <<~STONE
        double :: (Int) -> Int
        double := λ(x) { x * 2 }
        double(21)
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "parses multi-parameter function type" do
      code = <<~STONE
        add :: (Int, Int) -> Int
        add := λ(x, y) { x + y }
        add(20, 22)
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "parses zero-parameter function type" do
      code = <<~STONE
        answer :: () -> Int
        answer := λ() { 42 }
        answer()
      STONE
      expect(Stone.eval(code)).to eq(42)
    end
  end

  describe "nested function types require explicit parentheses" do
    it "parses curried function type with explicit parens" do
      code = <<~STONE
        add :: (Int) -> ((Int) -> Int)
        add := λ(x) { λ(y) { x + y } }
        add(20)(22)
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "parses deeply nested function type" do
      code = <<~STONE
        f :: (Int) -> ((Int) -> ((Int) -> Int))
        f := λ(a) { λ(b) { λ(c) { a + b + c } } }
        f(10)(20)(12)
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "rejects unparenthesized nested function types" do
      code = "f :: (Int) -> (Int) -> Int"
      expect { Stone.parse(code) }.to raise_error(Grammy::ParseError)
    end

    it "parses function returning function with parens" do
      code = <<~STONE
        makeAdder :: (Int) -> ((Int) -> Int)
        makeAdder := λ(n) { λ(x) { x + n } }
        add10 := makeAdder(10)
        add10(32)
      STONE
      expect(Stone.eval(code)).to eq(42)
    end
  end

  describe "function types in record fields" do
    it "allows function type in record field" do
      code = <<~STONE
        Handler := Record(callback :: (Int) -> Int)
        h := Handler(λ(x) { x * 2 })
        h.callback(21)
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "allows higher-order function type in record field" do
      code = <<~STONE
        Processor := Record(transform :: ((Int) -> Int, Int) -> Int)
        p := Processor(λ(f, x) { f(x) })
        double := λ(n) { n * 2 }
        p.transform(double, 21)
      STONE
      expect(Stone.eval(code)).to eq(42)
    end
  end

  describe "higher-order functions" do
    it "function that takes a function" do
      code = <<~STONE
        apply :: ((Int) -> Int, Int) -> Int
        apply := λ(f, x) { f(x) }
        double := λ(n) { n * 2 }
        apply(double, 21)
      STONE
      expect(Stone.eval(code)).to eq(42)
    end
  end

  describe "type declaration storage" do
    it "stores function type declarations" do
      code = <<~STONE
        double :: (Int) -> Int
        double := λ(x) { x * 2 }
        double(21)
      STONE
      result, scope = Stone.eval_with_scope(code)
      decl = scope.declared_type("double")
      expect(decl).to be_a(Stone::Type)
      expect(decl.function?).to be true
      expect(decl.to_s).to eq("(Int) -> Int")
    end
  end
end

RSpec.describe "Function Type Parsing" do
  describe "valid function types" do
    it "parses (Int) -> Int" do
      expect("f :: (Int) -> Int").to parse_as(:type_declaration)
    end

    it "parses (Int, Int) -> Bool" do
      expect("f :: (Int, Int) -> Bool").to parse_as(:type_declaration)
    end

    it "parses () -> Int" do
      expect("f :: () -> Int").to parse_as(:type_declaration)
    end

    it "parses nested with explicit parens" do
      expect("f :: (Int) -> ((Int) -> Int)").to parse_as(:type_declaration)
    end

    it "parses function taking function" do
      expect("f :: ((Int) -> Int) -> Int").to parse_as(:type_declaration)
    end
  end

  describe "invalid function types" do
    it "rejects unparenthesized params" do
      expect("f :: Int -> Int").not_to parse_as(:type_declaration)
    end

    it "rejects unparenthesized nested return" do
      expect("f :: (Int) -> (Int) -> Int").not_to parse_as(:type_declaration)
    end
  end
end
```

## Files to Create

1. `lib/stone/ast/function_type_annotation.rb` - AST node for function types in annotations
2. `spec/language/types/function_type_spec.rb` - Integration tests
3. `spec/unit/parser/function_type_parsing_spec.rb` - Parser tests

## Files to Modify

1. `lib/stone/grammar.rb` - Add function type syntax to type_annotation
2. `lib/stone/transform.rb` - Transform function type nodes
3. `lib/stone/ast/type_annotation.rb` - Add `to_type` method
4. `lib/stone/ast/type_declaration.rb` - Handle complex type annotations

## Acceptance Criteria

- [ ] `(Int) -> Int` parses as a function type annotation
- [ ] `(Int, Int) -> Bool` parses correctly
- [ ] `() -> Int` parses correctly (zero parameters)
- [ ] `(Int) -> ((Int) -> Int)` parses as nested function type
- [ ] `(Int) -> (Int) -> Int` is a parse error (requires explicit parens)
- [ ] Function types work in signatures: `f :: (Int) -> Int`
- [ ] Function types work in record fields: `Record(f :: (Int) -> Int)`
- [ ] Type declarations with function types are stored in registry
- [ ] All existing tests pass
- [ ] `make test` passes
- [ ] `make lint` passes

## Relationship to Other Features

### Prerequisites

- Basic type annotations (`x :: Int`)
- Type declaration tracking (`type-declaration-tracking.md`)

### Enables

- Generic type signatures: `List :: (Type) -> Type`
- Higher-order function type checking
- Type checking arguments (`type-checking-arguments.md`)

### Future Enhancements

- Union types in annotations (`Int | String`)
- Type application in annotations (`List(Int)`)
- Type inference for lambda parameters
- Explicit parameter type annotations: `λ(x :: Int) { ... }`

## Notes

- Function types are about documentation and tracking, not runtime behavior (yet)
- The LLVM representation is the same regardless of type annotation
- Currying is explicit - `λ(a) { λ(b) { ... } }` not automatic
- Type signatures don't change how functions are compiled (yet)
- Explicit parentheses for nested types prevents ambiguity
- This is foundational for generic types and type checking
