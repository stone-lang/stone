# Phase A: Static Type Checking System

## Overview

Implement a compile-time static type system for Stone that can determine the type of any expression. This provides the foundation for computed properties (Phase B) and enables better error messages and type safety.

## Prerequisites

- Phase 0 (Record as Constructor Function) should be completed first

## Goals

1. Implement `type` method on all AST nodes that returns their Stone type (e.g., `Type::Int`)
2. Implement `Type.of(expression)` as a special form that returns a Type object
3. Implement `as_String` property on all Types for string conversion
4. Track types through variable definitions, function returns, and property access
5. Remove the need for `PropertyRegistry` - property return types live in Type classes
6. Remove the need for `string_constants` tracking in llvm_module extensions
7. Provide clear error messages when types cannot be determined

## Current State

The codebase has ad-hoc type inference scattered across several files:

- `lib/stone/ast/property_access.rb`: `infer_type_from_node()` method handles literals, references, property access chains, and function calls
- `lib/stone/ast/reference.rb`: `type(mod)` method infers type from record instances, parameters, string constants, and globals
- `lib/stone/properties.rb`: `PropertyRegistry` maps types to property implementations
- `lib/stone/type/*.rb`: Minimal type objects (Int, Bool, String) that mainly define LLVM type mappings

The existing inference works for:

- Literals: `42` → Int, `TRUE` → Bool, `"hello"` → String
- Record constructors: `Point(1, 2)` → Point
- Variables with tracked assignments
- Property chains where return types are known

## Design

### 1. AST Node `type` Method

Instead of a separate TypeChecker module, implement a `type(context)` method on each AST node class. This is more object-oriented and keeps type logic close to the nodes.

```ruby
# In lib/stone/ast/integer_literal.rb
class IntegerLiteral < Stone::AST
  def type(context = nil)
    Stone::Type::Int
  end
end

# In lib/stone/ast/boolean_literal.rb
class BooleanLiteral < Stone::AST
  def type(context = nil)
    Stone::Type::Bool
  end
end

# In lib/stone/ast/reference.rb
class Reference < Stone::AST
  def type(context)
    context.lookup(@identifier) || fail(Stone::TypeError, "Unknown identifier: #{@identifier}")
  end
end

# In lib/stone/ast/property_access.rb
class PropertyAccess < Stone::AST
  def type(context)
    receiver_type = @receiver.type(context)
    receiver_type.property_return_type(@property)
  end
end
```

The base AST class should define the interface:

```ruby
# In lib/stone/ast.rb
class AST
  def type(context = nil)
    raise NotImplementedError, "#{self.class} must implement #type"
  end
end
```

### 2. Type Context

Create a `TypeContext` class to track type information during compilation:

```ruby
module Stone
  class TypeContext
    def initialize(mod = nil)
      @mod = mod
      @bindings = {}  # variable_name => Type
    end

    def bind(name, type)
      @bindings[name] = type
    end

    def lookup(name)
      @bindings[name] || lookup_in_module(name)
    end

    def record_type?(name)
      @mod&.record_type?(name)
    end

    def record_definition(name)
      @mod&.record_types&.[](name)
    end
  end
end
```

### 3. Type Objects Refactor

Enhance the existing type objects in `lib/stone/type/` to be proper singletons with metadata and an `as_String` property:

```ruby
module Stone
  module Type
    class Base
      def self.name
        raise NotImplementedError
      end

      def self.llvm_type
        raise NotImplementedError
      end

      def self.property_return_type(property_name)
        return self if property_name == "as_String"  # All types have as_String
        PROPERTY_TYPES[property_name]
      end

      # For Type.of() to return a Type that can be converted to String
      def self.as_String
        name
      end
    end

    class Int < Base
      PROPERTY_TYPES = {
        "positive?" => Bool,
        "negative?" => Bool,
        "zero?" => Bool,
        "abs" => Int,  # Future computed property
        "as_String" => String
      }.freeze

      def self.name = "Int"
      def self.llvm_type = LLVM::Int64.type
    end

    class Bool < Base
      PROPERTY_TYPES = {
        "not" => Bool,
        "as_String" => String
      }.freeze

      def self.name = "Bool"
      def self.llvm_type = LLVM::Int1.type
    end

    class String < Base
      PROPERTY_TYPES = {
        "byte_count" => Int,
        "empty?" => Bool,
        "as_String" => String
      }.freeze

      def self.name = "String"
      # ... llvm_type
    end
  end
end
```

**Note**: `as_String` is a property on Types themselves, not on values. When you call `Type.of(42).as_String`, you get `"Int"`.

### 4. Grammar Addition: Type.of()

Add `Type.of(expression)` as a special form. This should be parsed and handled at compile time.

In `lib/stone/grammar.rb`, add:

```ruby
rule(:type_of_expression) { str("Type.of") + parens(expression) }
```

Update the `primary` rule to include `type_of_expression`.

In `lib/stone/transform.rb`, add a transform that creates a `TypeOfExpression` AST node.

The `TypeOfExpression` node's `to_llir` should:

1. Determine the type at compile time using `TypeChecker.type_of(inner_expression, context)`
2. Return a reference to the Type object (for now, could just return the type name as a string)

### 5. Integration with ConstantDefinition

When processing `ConstantDefinition` nodes, register the type:

```ruby
# In ConstantDefinition#to_llir or during a pre-pass
context.bind(identifier, TypeChecker.type_of(value, context))
```

## Implementation Steps

### Step 1: Create Type Infrastructure

1. Create `lib/stone/type/base.rb` with the base type class
2. Update `lib/stone/type/Int.rb`, `Bool.rb`, `String.rb` to extend Base
3. Add property return type mappings to each type
4. Create `lib/stone/type_context.rb`

### Step 2: Create TypeChecker Module

1. Create `lib/stone/type_checker.rb`
2. Implement `type_of` for each AST node type
3. Extract and centralize the inference logic from `PropertyAccess#infer_type_from_node`
4. Add specs for each inference case

### Step 3: Add Type.of() Grammar and Transform

1. Add `type_of_expression` rule to grammar
2. Add transform to create AST node
3. Create `lib/stone/ast/type_of_expression.rb`
4. Implement `to_llir` that returns type name as string

### Step 4: Integrate Type Tracking

1. Create a type-tracking pass that runs before LLVM IR generation
2. Update `ConstantDefinition` to register types in context
3. Update `Reference` to use `TypeChecker` instead of ad-hoc inference
4. Update `PropertyAccess` to use `TypeChecker`

### Step 5: Testing

Add specs in `spec/unit/type_checker/`:

- `type_checker_spec.rb` - unit tests for TypeChecker module
- `type_context_spec.rb` - unit tests for TypeContext

Add specs in `spec/language/types/`:

- `type_of_spec.rb` - integration tests for Type.of()

## Test Cases

### Unit Tests for TypeChecker

```ruby
RSpec.describe Stone::TypeChecker do
  describe ".type_of" do
    context "with literals" do
      it "returns Int for integer literals" do
        node = Stone::AST::IntegerLiteral.new(42)
        expect(described_class.type_of(node, context)).to eq(Stone::Type::Int)
      end

      it "returns Bool for boolean literals" do
        node = Stone::AST::BooleanLiteral.new(true)
        expect(described_class.type_of(node, context)).to eq(Stone::Type::Bool)
      end

      it "returns String for string literals" do
        node = Stone::AST::StringLiteral.new("hello")
        expect(described_class.type_of(node, context)).to eq(Stone::Type::String)
      end
    end

    context "with references" do
      it "returns the bound type for known variables" do
        context.bind("x", Stone::Type::Int)
        node = Stone::AST::Reference.new("x")
        expect(described_class.type_of(node, context)).to eq(Stone::Type::Int)
      end

      it "raises for unknown variables" do
        node = Stone::AST::Reference.new("unknown")
        expect { described_class.type_of(node, context) }.to raise_error(Stone::TypeError)
      end
    end

    context "with property access" do
      it "returns the property's return type" do
        node = parse_and_transform("42.positive?")
        expect(described_class.type_of(node, context)).to eq(Stone::Type::Bool)
      end

      it "handles chained properties" do
        node = parse_and_transform("42.positive?.not")
        expect(described_class.type_of(node, context)).to eq(Stone::Type::Bool)
      end
    end

    context "with record constructors" do
      it "returns the record type" do
        # Setup: define Point record in context
        context.register_record_type("Point", point_definition)
        node = parse_and_transform("Point(1, 2)")
        type = described_class.type_of(node, context)
        expect(type.name).to eq("Point")
      end
    end
  end
end
```

### Integration Tests for Type.of()

Note: `Type.of()` returns a Type object. Use `.as_String` to get a string representation.

```ruby
RSpec.describe "Type.of() special form" do
  describe "with literals" do
    it "returns Int type for integer literals" do
      expect(Stone.eval("Type.of(42).as_String")).to eq("Int")
    end

    it "returns Bool type for boolean literals" do
      expect(Stone.eval("Type.of(TRUE).as_String")).to eq("Bool")
    end

    it "returns String type for string literals" do
      expect(Stone.eval('Type.of("hello").as_String')).to eq("String")
    end
  end

  describe "with expressions" do
    it "returns Bool for comparison results" do
      expect(Stone.eval("Type.of(5 < 3).as_String")).to eq("Bool")
    end

    it "returns Bool for property access returning Bool" do
      expect(Stone.eval("Type.of(42.positive?).as_String")).to eq("Bool")
    end
  end

  describe "with variables" do
    it "returns the type of a defined constant" do
      code = <<~STONE
        x := 42
        Type.of(x).as_String
      STONE
      expect(Stone.eval(code)).to eq("Int")
    end
  end

  describe "with records" do
    it "returns the record type" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        p := Point(1, 2)
        Type.of(p).as_String
      STONE
      expect(Stone.eval(code)).to eq("Point")
    end
  end

  describe "Type object itself" do
    it "Type.of returns a Type that can be compared" do
      code = <<~STONE
        Type.of(42) == Type.of(100)
      STONE
      expect(Stone.eval(code)).to be true
    end

    it "different types are not equal" do
      code = <<~STONE
        Type.of(42) == Type.of(TRUE)
      STONE
      expect(Stone.eval(code)).to be false
    end
  end

  describe "metatypes" do
    it "Type.of(Type.of(anything)) returns Type" do
      code = <<~STONE
        Type.of(Type.of(42)).as_String
      STONE
      expect(Stone.eval(code)).to eq("Type")
    end

    it "Type.of(Type) returns Type" do
      code = <<~STONE
        Type.of(Type).as_String
      STONE
      expect(Stone.eval(code)).to eq("Type")
    end

    it "Type.as_String returns 'Type'" do
      expect(Stone.eval("Type.as_String")).to eq("Type")
    end
  end
end
```

## Files to Create

1. `lib/stone/type/base.rb` - Base type class with property_return_type and as_String
2. `lib/stone/type_context.rb` - Type context for tracking bindings
3. `lib/stone/ast/type_of_expression.rb` - AST node for Type.of()
4. `lib/stone/error/type_error.rb` - Custom error class
5. `spec/unit/type_context_spec.rb`
6. `spec/unit/ast/*_type_spec.rb` - Tests for type() method on each AST node
7. `spec/language/types/type_of_spec.rb`

## Files to Modify

1. `lib/stone/ast.rb` - Add abstract `type(context)` method
2. `lib/stone/ast/integer_literal.rb` - Add `type` method returning Type::Int
3. `lib/stone/ast/boolean_literal.rb` - Add `type` method returning Type::Bool
4. `lib/stone/ast/string_literal.rb` - Add `type` method returning Type::String
5. `lib/stone/ast/reference.rb` - Add `type` method using context lookup
6. `lib/stone/ast/property_access.rb` - Add `type` method, remove ad-hoc inference
7. `lib/stone/ast/function_call.rb` - Add `type` method
8. `lib/stone/ast/lambda.rb` - Add `type` method
9. `lib/stone/ast/block.rb` - Add `type` method
10. `lib/stone/type/Int.rb` - Extend Base, add property types, add as_String
11. `lib/stone/type/Bool.rb` - Extend Base, add property types, add as_String
12. `lib/stone/type/String.rb` - Extend Base, add property types, add as_String
13. `lib/stone/types.rb` - Require base.rb
14. `lib/stone/grammar.rb` - Add type_of_expression rule
15. `lib/stone/transform.rb` - Add transform for type_of_expression

## Files to Remove

1. `lib/stone/properties.rb` - PropertyRegistry no longer needed
2. Remove `string_constants` tracking from `lib/extensions/llvm_module.rb` (if possible)

## Acceptance Criteria

- [ ] All AST nodes have a `type(context)` method
- [ ] `Type.of(42)` returns `Type::Int` (a Type object)
- [ ] `Type.of(42).as_String` returns `"Int"`
- [ ] `Type.of(TRUE).as_String` returns `"Bool"`
- [ ] `Type.of("hello").as_String` returns `"String"`
- [ ] `Type.of(x).as_String` returns the type name of variable `x`
- [ ] `Type.of(Point(1, 2)).as_String` returns `"Point"` for a defined Point record
- [ ] `Type.of(42.positive?).as_String` returns `"Bool"`
- [ ] `Type.of(42) == Type.of(100)` returns `TRUE` (same type)
- [ ] `Type.of(42) == Type.of(TRUE)` returns `FALSE` (different types)
- [ ] PropertyRegistry is removed
- [ ] Clear error messages when types cannot be determined
- [ ] All existing tests continue to pass
- [ ] Linting passes (`make lint`)
- [ ] New specs have good coverage

## Notes

- This is compile-time only; no runtime type information yet
- Focus on cases where type is statically determinable
- For unknown types (e.g., untyped function parameters), raise a clear error
- Record types should work the same as built-in types
- The `Type.of()` special form is for debugging/introspection; it's not required for property access to work
- `string_constants` in llvm_module.rb should be removable once TypeContext tracks string types

## References

- [Type Checking in Compiler Design](https://www.geeksforgeeks.org/compiler-design/type-checking-in-compiler-design/)
- [Hindley-Milner Type System](https://en.wikipedia.org/wiki/Hindley%E2%80%93Milner_type_system)
- Current ad-hoc inference in `lib/stone/ast/property_access.rb`
