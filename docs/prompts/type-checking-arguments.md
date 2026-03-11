# Type Checking Function Arguments

## Overview

Implement type checking for function arguments in Stone. When a function has a type signature, verify that arguments passed at call sites match the expected parameter types. This catches type errors at compile time rather than runtime.

## Prerequisites

- Type annotations work (`x :: Int`)
- Function type syntax (`(Int) -> Int`)
- Type annotation scoping (type references resolve from scope)
- Basic type system (Int, Bool, String, Null, Records)

## Goals

1. Type check arguments against function parameter types
2. Provide clear error messages on type mismatch
3. Support type checking for built-in functions
4. Support type checking for user-defined lambdas with signatures
5. Handle NULL compatibility with nullable types
6. Support record types in signatures

## Design Decisions

### When to Type Check

Type checking happens at compile time during AST-to-LLIR transformation:

1. When a function call is encountered
2. Look up the function's type signature
3. Compare argument types to parameter types
4. Error if incompatible

### Inference vs Annotation

For now, focus on **checking** rather than inference:

- If a function has a type signature, check it
- If no signature, skip type checking (dynamic typing fallback)
- Future: infer types and check even without signatures

### Error Messages

Provide helpful error messages:

```text
Type error at line 5, column 10:
  Argument 1 of 'add' has type String, expected Int
  in call: add("hello", 42)
```

## Implementation Steps

### Step 1: Track Function Signatures

```ruby
# In lib/extensions/llvm_module.rb
def function_signatures
  @function_signatures ||= {}
end

def register_function_signature(name, param_types, return_type)
  function_signatures[name] = {
    param_types: param_types,
    return_type: return_type
  }
end

def get_function_signature(name)
  function_signatures[name]
end
```

### Step 2: Parse and Store Signatures

When a type signature is defined, store it:

```ruby
# When processing: double :: (Int) -> Int
# Store: { param_types: [Int], return_type: Int }
```

### Step 3: Type Check at Call Sites

```ruby
# In lib/stone/ast/function_call.rb
def to_llir(builder, mod)
  # Check types if signature exists
  check_argument_types(mod) if should_type_check?(mod)
  
  # ... existing code generation
end

private def should_type_check?(mod)
  mod.get_function_signature(function_name).present?
end

private def check_argument_types(mod)
  signature = mod.get_function_signature(function_name)
  expected_types = signature[:param_types]
  
  arguments.each_with_index do |arg, index|
    expected = expected_types[index]
    actual = arg.infer_type(mod)
    
    unless types_compatible?(expected, actual)
      raise Stone::TypeError, type_error_message(index, expected, actual)
    end
  end
end

private def types_compatible?(expected, actual)
  return true if expected == actual
  return true if actual == Stone::Type::Null  # NULL compatible with anything (for now)
  return true if expected.is_a?(Stone::Type::Union) && expected.alternatives.include?(actual)
  
  false
end

private def type_error_message(index, expected, actual)
  "Argument #{index + 1} of '#{function_name}' has type #{actual.name}, expected #{expected.name}"
end
```

### Step 4: Infer Argument Types

Add type inference to AST nodes:

```ruby
# In lib/stone/ast/integer_literal.rb
def infer_type(_mod)
  Stone::Type::Int
end

# In lib/stone/ast/string_literal.rb
def infer_type(_mod)
  Stone::Type::String
end

# In lib/stone/ast/boolean_literal.rb
def infer_type(_mod)
  Stone::Type::Bool
end

# In lib/stone/ast/null_literal.rb
def infer_type(_mod)
  Stone::Type::Null
end

# In lib/stone/ast/reference.rb
def infer_type(mod)
  # Look up the variable's type
  if mod.record_instance?(identifier)
    record_type_name = mod.record_instance_type(identifier)
    mod.get_type(record_type_name)
  elsif mod.get_function_signature(identifier)
    signature = mod.get_function_signature(identifier)
    Stone::Type::Function.new(signature[:param_types], signature[:return_type])
  else
    # Try to infer from global's LLVM type
    infer_from_global(mod)
  end
end

# In lib/stone/ast/function_call.rb
def infer_type(mod)
  signature = mod.get_function_signature(function_name)
  signature ? signature[:return_type] : Stone::Type::Int  # Default to Int if unknown
end
```

### Step 5: Register Built-in Function Signatures

```ruby
# In lib/stone/built_ins.rb or during module initialization
def register_builtin_signatures(mod)
  # Comparison operators
  mod.register_function_signature("==", [Stone::Type::Int, Stone::Type::Int], Stone::Type::Bool)
  mod.register_function_signature("!=", [Stone::Type::Int, Stone::Type::Int], Stone::Type::Bool)
  mod.register_function_signature("<", [Stone::Type::Int, Stone::Type::Int], Stone::Type::Bool)
  mod.register_function_signature("<=", [Stone::Type::Int, Stone::Type::Int], Stone::Type::Bool)
  mod.register_function_signature(">", [Stone::Type::Int, Stone::Type::Int], Stone::Type::Bool)
  mod.register_function_signature(">=", [Stone::Type::Int, Stone::Type::Int], Stone::Type::Bool)
  
  # Arithmetic (when added)
  mod.register_function_signature("+", [Stone::Type::Int, Stone::Type::Int], Stone::Type::Int)
  mod.register_function_signature("-", [Stone::Type::Int, Stone::Type::Int], Stone::Type::Int)
  mod.register_function_signature("*", [Stone::Type::Int, Stone::Type::Int], Stone::Type::Int)
  mod.register_function_signature("/", [Stone::Type::Int, Stone::Type::Int], Stone::Type::Int)
  
  # Control flow
  mod.register_function_signature("if", [Stone::Type::Bool, Stone::Type::Function, Stone::Type::Function], Stone::Type::Int)
end
```

### Step 6: Handle Lambda Signatures

When a lambda has a type signature, store it:

```ruby
# In lib/stone/ast/constant_definition.rb
def to_llir(builder, mod)
  # If there's a type signature for this constant
  if has_type_signature?
    register_signature(mod)
  end
  
  # ... existing code
end

private def register_signature(mod)
  if @type_signature.is_a?(Stone::AST::FunctionType)
    mod.register_function_signature(
      identifier,
      @type_signature.param_types.map { |t| t.resolve(mod.type_scope) },
      @type_signature.return_type.resolve(mod.type_scope)
    )
  end
end
```

## Test Cases

```ruby
RSpec.describe "Type Checking Arguments" do
  describe "basic type checking" do
    it "allows correct types" do
      code = <<~STONE
        add :: (Int, Int) -> Int
        add := λ(x, y) { x + y }
        add(1, 2)
      STONE
      expect(Stone.eval(code)).to eq(3)
    end

    it "raises error on type mismatch" do
      code = <<~STONE
        double :: (Int) -> Int
        double := λ(x) { x * 2 }
        double("hello")
      STONE
      expect { Stone.eval(code) }.to raise_error(Stone::TypeError, /expected Int/)
    end

    it "raises error on wrong argument type" do
      code = <<~STONE
        greet :: (String) -> String
        greet := λ(name) { name }
        greet(42)
      STONE
      expect { Stone.eval(code) }.to raise_error(Stone::TypeError, /expected String/)
    end
  end

  describe "argument count" do
    it "raises error on too few arguments" do
      code = <<~STONE
        add :: (Int, Int) -> Int
        add := λ(x, y) { x + y }
        add(1)
      STONE
      expect { Stone.eval(code) }.to raise_error(Stone::ArgumentError, /wrong number/)
    end

    it "raises error on too many arguments" do
      code = <<~STONE
        double :: (Int) -> Int
        double := λ(x) { x * 2 }
        double(1, 2)
      STONE
      expect { Stone.eval(code) }.to raise_error(Stone::ArgumentError, /wrong number/)
    end
  end

  describe "NULL compatibility" do
    it "allows NULL for any parameter type" do
      code = <<~STONE
        process :: (Int) -> Int
        process := λ(x) { if(x == NULL, { 0 }, { x }) }
        process(NULL)
      STONE
      expect(Stone.eval(code)).to eq(0)
    end
  end

  describe "record types" do
    it "type checks record arguments" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        distance :: (Point) -> Int
        distance := λ(p) { p.x + p.y }
        pt := Point(3, 4)
        distance(pt)
      STONE
      expect(Stone.eval(code)).to eq(7)
    end

    it "raises error on wrong record type" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        Size := Record(width :: Int, height :: Int)
        distance :: (Point) -> Int
        distance := λ(p) { p.x + p.y }
        s := Size(3, 4)
        distance(s)
      STONE
      expect { Stone.eval(code) }.to raise_error(Stone::TypeError, /expected Point/)
    end
  end

  describe "function arguments" do
    it "type checks higher-order function arguments" do
      code = <<~STONE
        apply :: ((Int) -> Int, Int) -> Int
        apply := λ(f, x) { f(x) }
        double :: (Int) -> Int
        double := λ(n) { n * 2 }
        apply(double, 21)
      STONE
      expect(Stone.eval(code)).to eq(42)
    end
  end

  describe "without type signatures" do
    it "skips type checking when no signature" do
      code = <<~STONE
        add := λ(x, y) { x + y }
        add(1, 2)
      STONE
      # No type error even though we can't verify types
      expect(Stone.eval(code)).to eq(3)
    end
  end

  describe "error messages" do
    it "includes function name in error" do
      code = <<~STONE
        foo :: (Int) -> Int
        foo := λ(x) { x }
        foo("oops")
      STONE
      expect { Stone.eval(code) }.to raise_error(Stone::TypeError, /foo/)
    end

    it "includes argument position in error" do
      code = <<~STONE
        bar :: (Int, String, Bool) -> Int
        bar := λ(a, b, c) { a }
        bar(1, 2, TRUE)
      STONE
      expect { Stone.eval(code) }.to raise_error(Stone::TypeError, /Argument 2/)
    end

    it "includes expected and actual types" do
      code = <<~STONE
        baz :: (Bool) -> Bool
        baz := λ(x) { x }
        baz(42)
      STONE
      expect { Stone.eval(code) }.to raise_error(Stone::TypeError, /Int.*Bool/)
    end
  end
end
```

## Files to Create

1. `spec/language/types/type_checking_spec.rb` - Integration tests

## Files to Modify

1. `lib/extensions/llvm_module.rb` - Add function_signatures tracking
2. `lib/stone/ast/function_call.rb` - Add type checking before code gen
3. `lib/stone/ast/integer_literal.rb` - Add infer_type method
4. `lib/stone/ast/string_literal.rb` - Add infer_type method
5. `lib/stone/ast/boolean_literal.rb` - Add infer_type method
6. `lib/stone/ast/null_literal.rb` - Add infer_type method
7. `lib/stone/ast/reference.rb` - Add infer_type method
8. `lib/stone/ast/constant_definition.rb` - Register signatures
9. `lib/stone/built_ins.rb` - Register built-in signatures

## Acceptance Criteria

- [ ] Functions with signatures type-check their arguments
- [ ] Type mismatch raises Stone::TypeError
- [ ] Error message includes function name
- [ ] Error message includes argument position
- [ ] Error message includes expected and actual types
- [ ] NULL is compatible with any type (temporary)
- [ ] Functions without signatures skip type checking
- [ ] Record types are checked correctly
- [ ] Function types (higher-order) are checked
- [ ] All existing tests pass
- [ ] `make test` passes
- [ ] `make lint` passes

## Relationship to Other Features

### Prerequisites

- Type annotations
- Function type syntax
- Basic type system

### Enables

- Catching type errors at compile time
- Better error messages
- Foundation for type inference
- Implicit type passing (checking type params)

### Future Enhancements

- Type inference (check without explicit signatures)
- Gradual typing (mix typed and untyped)
- Type error recovery (report multiple errors)
- Source location in error messages

## Notes

- Start with checking only, not inference
- NULL compatibility is temporary until union types
- Skip checking for untyped functions (gradual typing approach)
- Consider caching inferred types for performance
- Error messages should be actionable and clear

## Type Widening (Future Work)

Type widening allows assignment from narrower to wider union types:

```stone
x :: Int
y :: Int | Null
y := x   # Valid: Int is compatible with Int | Null
```

The existing `Stone::Type#compatible_with?` method handles this correctly:

- `Int.compatible_with?(Int | Null)` returns `true` (Int matches the Int alternative)
- `(Int | Null).compatible_with?(Int)` returns `false` (would require runtime check)

When implementing type checking:

1. Check if `actual_type.compatible_with?(expected_type)`
2. For union expected types, any alternative match is valid
3. For union actual types, all alternatives must be compatible with expected

Test cases to add:

```ruby
it "allows assigning Int to Int | Null parameter" do
  code = <<~STONE
    process :: (Int | Null) -> Int
    process := λ(x) { 42 }
    x :: Int
    x := 5
    process(x)
  STONE
  expect(Stone.eval(code)).to eq(42)
end

it "allows assigning narrower union to wider union parameter" do
  code = <<~STONE
    process :: (Int | String | Null) -> Int
    process := λ(x) { 42 }
    x :: Int | Null
    x := 5
    process(x)
  STONE
  expect(Stone.eval(code)).to eq(42)
end
```
