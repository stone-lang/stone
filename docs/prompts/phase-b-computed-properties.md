# Phase B: Computed Property Desugaring

## Overview

Implement computed properties for Stone. Users can define properties on types using the syntax `Type@property := lambda`, and property access `expr.property` will desugar to `Type@property(expr)` when no constant with that name exists.

## Prerequisites

- Phase A (Static Type System) must be completed first
- TypeChecker module must be available to determine expression types

## Goals

1. Add syntax for defining computed properties: `Type@property := lambda`
2. Implement property lookup that finds computed properties by type
3. Desugar `expr.property` to `Type@property(expr)` during transformation
4. Handle the disambiguation rule: constants take precedence over computed properties

## Design

### Syntax

```stone
# Define a computed property on Int
Int@abs := λ(this) { if(this.negative?, { -(this) }, { this }) }

# Define a computed property on String
String@empty? := λ(this) { this.byte_count == 0 }

# Usage - these desugar to function calls
x := -42
x.abs        # desugars to: Int@abs(x)

s := ""
s.empty?     # desugars to: String@empty?(s)
```

### Grammar Changes

Add to `lib/stone/grammar.rb`:

```ruby
# Computed property definition identifier: Type@property
terminal(:computed_property_id) { /[A-Z][a-zA-Z0-9_]*@[a-zA-Z_][a-zA-Z0-9_]*[!?]?/ }

# Update definition rule to allow computed property definitions
rule(:definition) { (computed_property_id | identifier) + ws! + define_op + ws! + expression }
```

The `computed_property_id` pattern:

- Type name: `[A-Z][a-zA-Z0-9_]*` (starts with uppercase)
- Separator: `@`
- Property name: `[a-zA-Z_][a-zA-Z0-9_]*[!?]?` (standard identifier, can end with `!` or `?`)

### Transform Changes

In `lib/stone/transform.rb`, update the definition transform:

```ruby
transform(:definition) do |node|
  identifier_token = node.children.first
  expression_node = node.find_child(:expression)
  value_expression = transform(expression_node)

  identifier_text = identifier_token.text

  if identifier_text.include?("@")
    # Computed property definition: Type@property
    type_name, property_name = identifier_text.split("@", 2)
    Stone::AST::ComputedPropertyDefinition.new(type_name, property_name, value_expression)
  else
    Stone::AST::ConstantDefinition.new(identifier_text, value_expression)
  end
end
```

### AST Node: ComputedPropertyDefinition

Create `lib/stone/ast/computed_property_definition.rb`:

```ruby
module Stone
  class AST
    class ComputedPropertyDefinition < Stone::AST
      attr_reader :type_name, :property_name, :lambda

      def initialize(type_name, property_name, lambda)
        @name = :computed_property_definition
        @type_name = type_name
        @property_name = property_name
        @lambda = lambda
      end

      def to_llir(builder, mod)
        # Generate the lambda function
        func = @lambda.to_llir(builder, mod)

        # Register the computed property
        mod.register_computed_property(type_name, property_name, func)

        # Return the function (for consistency)
        func
      end
    end
  end
end
```

### ComputedPropertyRegistry

Create `lib/stone/computed_properties.rb`:

```ruby
module Stone
  module ComputedPropertyRegistry
    @properties = {}  # { type_name => { property_name => function } }

    def self.register(type_name, property_name, func)
      @properties[type_name] ||= {}
      @properties[type_name][property_name] = func
    end

    def self.lookup(type_name, property_name)
      @properties.dig(type_name, property_name)
    end

    def self.has_property?(type_name, property_name)
      @properties.dig(type_name, property_name) != nil
    end

    def self.clear!
      @properties = {}
    end
  end
end
```

### Module Extensions

Add to `lib/extensions/llvm_module.rb`:

```ruby
def computed_properties
  @computed_properties ||= {}  # { type_name => { property_name => function } }
end

def register_computed_property(type_name, property_name, func)
  computed_properties[type_name] ||= {}
  computed_properties[type_name][property_name] = func
end

def lookup_computed_property(type_name, property_name)
  computed_properties.dig(type_name, property_name)
end
```

### PropertyAccess Changes

Update `lib/stone/ast/property_access.rb` to support computed properties:

```ruby
def to_llir(builder, mod)
  # 1. Check if this is a record field access (existing)
  return access_record_field(builder, mod) if record_field_access?(mod)

  # 2. Check if receiver.property is a known constant name
  if constant_access?(mod)
    return access_constant(builder, mod)
  end

  # 3. Check for built-in property (existing behavior)
  receiver_type = infer_type(@receiver, mod)

  if builtin_property?(receiver_type)
    return access_builtin_property(builder, mod, receiver_type)
  end

  # 4. Check for computed property (new behavior)
  if computed_property?(mod, receiver_type)
    return access_computed_property(builder, mod, receiver_type)
  end

  fail Stone::PropertyError, "Property '#{@property}' not found for type '#{receiver_type}'"
end

private def computed_property?(mod, receiver_type)
  mod.lookup_computed_property(receiver_type, @property) != nil
end

private def access_computed_property(builder, mod, receiver_type)
  func = mod.lookup_computed_property(receiver_type, @property)
  receiver_value = @receiver.to_llir(builder, mod)

  # Call the computed property function with receiver as argument
  builder.call(func, receiver_value, "#{@property}_result")
end

private def constant_access?(mod)
  # Check if "ReceiverName.property" forms a constant name
  return false unless @receiver.is_a?(Reference)

  constant_name = "#{@receiver.identifier}.#{@property}"
  mod.globals[constant_name] != nil
end

private def access_constant(builder, mod)
  constant_name = "#{@receiver.identifier}.#{@property}"
  global = mod.globals[constant_name]
  builder.load(global, constant_name)
end
```

### Disambiguation Rule

When `a.b` is encountered:

1. If `a` is a record instance, check for field `b` first
2. If `a.b` is a defined constant name, access the constant
3. If `a` has a built-in property `b`, use it
4. If type of `a` has a computed property `b`, use it
5. Otherwise, raise PropertyError

If a constant shadows a computed property, emit a warning (optional for now).

## Implementation Steps

### Step 1: Grammar and Parsing

1. Add `computed_property_id` terminal to grammar
2. Update `definition` rule to match both patterns
3. Add parser tests for `Type@property := ...` syntax

### Step 2: AST Node

1. Create `lib/stone/ast/computed_property_definition.rb`
2. Add to requires in `lib/stone/ast.rb` or where appropriate
3. Add unit tests for the new AST node

### Step 3: Transform

1. Update `transform(:definition)` to detect computed property syntax
2. Create `ComputedPropertyDefinition` nodes for `Type@property` patterns
3. Add transform tests

### Step 4: Module Extensions

1. Add computed property registry to LLVM::Module extension
2. Implement `register_computed_property` and `lookup_computed_property`

### Step 5: PropertyAccess Integration

1. Update `PropertyAccess#to_llir` to check for computed properties
2. Implement `access_computed_property` method
3. Ensure disambiguation order is correct

### Step 6: Integration Tests

1. Create `spec/language/properties/computed_properties_spec.rb`
2. Test all three target properties: `Int@abs`, `String@empty?`, `Bool@not`
3. Test disambiguation (constant vs computed property)

## Test Cases

### Parser Tests

```ruby
RSpec.describe "Computed property parsing" do
  it "parses computed property definitions" do
    code = "Int@abs := λ(this) { this }"
    result = Stone::Grammar.new.parse(code)
    expect(result).to be_successful
  end

  it "parses computed property with predicate name" do
    code = "String@empty? := λ(this) { TRUE }"
    result = Stone::Grammar.new.parse(code)
    expect(result).to be_successful
  end
end
```

### Transform Tests

```ruby
RSpec.describe "Computed property transform" do
  it "transforms Type@property to ComputedPropertyDefinition" do
    ast = Stone.compile("Int@abs := λ(this) { this }")
    definition = ast.statements.first
    expect(definition).to be_a(Stone::AST::ComputedPropertyDefinition)
    expect(definition.type_name).to eq("Int")
    expect(definition.property_name).to eq("abs")
  end
end
```

### Integration Tests

```ruby
RSpec.describe "Computed Properties" do
  describe "Int@abs" do
    before do
      # Define the abs property (this would normally be in prelude)
      Stone.eval("Int@abs := λ(this) { if(this.negative?, { -(this) }, { this }) }")
    end

    it "returns the absolute value of positive integers" do
      expect(Stone.eval("42.abs")).to eq(42)
    end

    it "returns the absolute value of negative integers" do
      expect(Stone.eval("(-42).abs")).to eq(42)
    end

    it "returns zero for zero" do
      expect(Stone.eval("0.abs")).to eq(0)
    end

    it "works on references" do
      code = <<~STONE
        x := -100
        x.abs
      STONE
      expect(Stone.eval(code)).to eq(100)
    end
  end

  describe "String@empty?" do
    before do
      Stone.eval('String@empty? := λ(this) { this.byte_count == 0 }')
    end

    it "returns TRUE for empty strings" do
      expect(Stone.eval('"".empty?')).to be true
    end

    it "returns FALSE for non-empty strings" do
      expect(Stone.eval('"hello".empty?')).to be false
    end

    it "works on references" do
      code = <<~STONE
        s := ""
        s.empty?
      STONE
      expect(Stone.eval(code)).to be true
    end
  end

  describe "Bool@not" do
    before do
      Stone.eval("Bool@not := λ(this) { if(this, { FALSE }, { TRUE }) }")
    end

    it "returns FALSE for TRUE" do
      # Note: This tests computed property, not built-in
      expect(Stone.eval("TRUE.not")).to be false
    end

    it "returns TRUE for FALSE" do
      expect(Stone.eval("FALSE.not")).to be true
    end
  end

  describe "disambiguation" do
    it "prefers constants over computed properties" do
      code = <<~STONE
        Int@test := λ(this) { 100 }
        Int.test := 42
        5.test
      STONE
      # This should use the constant Int.test, not the computed property
      # Actually wait - Int.test is a constant, 5.test would use computed property
      # Let me reconsider...
    end

    it "prefers record fields over computed properties" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        Point@x := λ(this) { 999 }
        p := Point(10, 20)
        p.x
      STONE
      expect(Stone.eval(code)).to eq(10)  # Record field, not computed property
    end
  end
end
```

## Files to Create

1. `lib/stone/ast/computed_property_definition.rb` - AST node
2. `lib/stone/computed_properties.rb` - Registry module (optional, can use module extension)
3. `spec/unit/parser/computed_property_parsing_spec.rb`
4. `spec/unit/transform/computed_property_transform_spec.rb`
5. `spec/unit/ast/computed_property_definition_spec.rb`
6. `spec/language/properties/computed_properties_spec.rb`

## Files to Modify

1. `lib/stone/grammar.rb` - Add computed_property_id terminal, update definition rule
2. `lib/stone/transform.rb` - Update definition transform
3. `lib/stone/ast/property_access.rb` - Add computed property lookup and access
4. `lib/extensions/llvm_module.rb` - Add computed property registry

## Acceptance Criteria

- [ ] `Int@abs := λ(this) { ... }` syntax parses correctly
- [ ] `x.abs` desugars to `Int@abs(x)` when `x` is known to be Int
- [ ] String@empty? works with `"".empty?`
- [ ] Bool@not works with `TRUE.not`
- [ ] Record fields take precedence over computed properties
- [ ] Constants take precedence over computed properties (when applicable)
- [ ] Clear error when property not found
- [ ] All existing tests continue to pass
- [ ] Linting passes (`make lint`)

## Notes

- The `this` parameter name is conventional but not enforced
- Type checking uses `TypeChecker.type_of()` from Phase A
- For now, computed properties only work when the receiver type can be statically determined
- Future work: inheritance/trait-like sharing of computed properties across types

## Challenges

1. **Negation function**: `Int@abs` uses `-(this)` which requires a unary minus function. If not available, use `0 - this` instead: `λ(this) { if(this.negative?, { 0 - this }, { this }) }`

2. **State isolation**: Computed properties are registered at compile time. Each `Stone.eval()` call may need to start fresh or accumulate properties. Consider using the module's registry rather than a global one.

3. **Type inference order**: The computed property definition must be processed before it's used. This should work naturally with top-to-bottom evaluation.
