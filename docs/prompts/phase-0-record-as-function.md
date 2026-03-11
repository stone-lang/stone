# Phase 0: Record as Constructor Function

## Overview

Refactor record instantiation so that `Record(...)` returns a constructor function rather than using a separate `AST::RecordInstantiation` node. This aligns with functional programming principles where types are first-class and constructors are just functions.

## Goals

1. Remove `AST::RecordInstantiation` class
2. Make `Record(field :: Type, ...)` return a constructor function
3. Calling the constructor function creates instances: `Point(1, 2)`
4. Unify record construction with regular function calls via `AST::FunctionCall`

## Current State

Currently, record instantiation has special handling:

1. `Record(x :: Int, y :: Int)` creates a `RecordDefinition` AST node
2. When assigned: `Point := Record(...)`, the definition is registered
3. `Point(1, 2)` is parsed as a `FunctionCall` but handled specially in `FunctionCall#to_llir`:

   ```ruby
   # In function_call.rb
   return RecordInstantiation.new(@function_name, @arguments).to_llir(builder, mod) if record_constructor?(mod)
   ```

4. `AST::RecordInstantiation` generates the LLVM struct creation

## Desired State

1. `Record(x :: Int, y :: Int)` returns a **function** that:
   - Takes arguments matching the field types
   - Returns an instance (LLVM struct) of the record type
2. `Point := Record(...)` binds this constructor function to `Point`
3. `Point(1, 2)` is a regular function call - no special handling needed
4. `AST::RecordInstantiation` is deleted

## Design

### RecordDefinition Changes

Update `lib/stone/ast/record_definition.rb`:

```ruby
class RecordDefinition < Stone::AST
  def to_llir(builder, mod)
    # Register the record type (for type checking)
    mod.register_record_type(record_type_name, self)

    # Generate and return a constructor function
    generate_constructor_function(mod)
  end

  private def generate_constructor_function(mod)
    func_name = "__record_constructor_#{unique_id}__"
    func_type = constructor_function_type

    mod.functions.add(func_name, func_type).tap do |func|
      build_constructor_body(func, mod)
    end
  end

  private def constructor_function_type
    # (field_types...) -> struct_type
    LLVM::Type.function(field_llvm_types, struct_type)
  end

  private def build_constructor_body(func, mod)
    func.basic_blocks.append("entry").build do |b|
      # Build struct from parameters
      struct = LLVM::Value.null(struct_type)
      fields.each_with_index do |_field, i|
        struct = b.insert_value(struct, func.params[i], i)
      end
      b.ret(struct)
    end
  end
end
```

### FunctionCall Changes

Simplify `lib/stone/ast/function_call.rb` by removing the record constructor special case:

```ruby
def to_llir(builder, mod)
  # Remove this special case:
  # return RecordInstantiation.new(...) if record_constructor?(mod)

  # Just call the function - if it's a record constructor, it's already a function
  func = mod.lookup_function(@function_name)
  fail "Unknown function: #{@function_name}" unless func

  args = @arguments.map { |arg| arg.to_llir(builder, mod) }
  builder.call(func, *args)
end
```

### Record Type Naming

The record needs a name for type checking. Options:

**Option A**: Anonymous records get auto-generated names

```stone
Point := Record(x :: Int, y :: Int)  # Type name inferred from binding
```

**Option B**: Records are always anonymous, name comes from binding

- The `ConstantDefinition` that binds the record tells the record its name

Recommend **Option B** - the record definition itself doesn't know its name; it learns it when bound.

### ConstantDefinition Integration

Update `lib/stone/ast/constant_definition.rb`:

```ruby
def to_llir(builder, mod)
  value = @expression.to_llir(builder, mod)

  # If we're binding a record constructor, register the type name
  if @expression.is_a?(RecordDefinition)
    mod.register_record_type_name(@identifier, @expression)
    mod.register_function_alias(@identifier, value)
  else
    # ... existing global variable logic
  end

  value
end
```

## Implementation Steps

### Step 1: Update RecordDefinition

1. Add `generate_constructor_function` method
2. Update `to_llir` to return the constructor function
3. Remove direct struct creation (move to constructor body)

### Step 2: Update ConstantDefinition

1. Detect when binding a RecordDefinition
2. Register type name with the record
3. Register function alias for the constructor

### Step 3: Simplify FunctionCall

1. Remove `record_constructor?` check
2. Remove `RecordInstantiation` delegation
3. Let all function calls go through the same path

### Step 4: Delete RecordInstantiation

1. Remove `lib/stone/ast/record_instantiation.rb`
2. Remove require statements
3. Update any references

### Step 5: Update Module Extensions

1. Update `register_record_type` to handle the new structure
2. Ensure `record_instance_type` tracking still works

## Test Cases

Existing record tests should continue to pass:

```ruby
# From spec/language/records/record_spec.rb
RSpec.describe "Records" do
  it "allows a record type to be defined with typed fields" do
    code = <<~STONE
      Point := Record(x :: Int, y :: Int)
      Point
    STONE
    expect { Stone.eval(code) }.not_to raise_error
  end

  it "creates a record instance with provided values" do
    code = <<~STONE
      Person := Record(name :: String, age :: Int)
      p := Person("Craig", 54)
      p.age
    STONE
    expect(Stone.eval(code)).to eq(54)
  end

  it "allows accessing fields" do
    code = <<~STONE
      Point := Record(x :: Int, y :: Int)
      pt := Point(10, 20)
      pt.x
    STONE
    expect(Stone.eval(code)).to eq(10)
  end
end
```

Additional tests for the refactor:

```ruby
RSpec.describe "Record as Constructor Function" do
  it "Record(...) returns a function" do
    code = <<~STONE
      Point := Record(x :: Int, y :: Int)
      Type.of(Point)
    STONE
    # Point should be a Function type (or similar)
    expect(Stone.eval(code)).to satisfy { |t| t.respond_to?(:call) || t.is_a?(Function) }
  end

  it "constructor function can be called directly" do
    code = <<~STONE
      Point := Record(x :: Int, y :: Int)
      constructor := Point
      p := constructor(5, 10)
      p.x
    STONE
    expect(Stone.eval(code)).to eq(5)
  end
end
```

## Files to Create

None - this is a refactoring task.

## Files to Modify

1. `lib/stone/ast/record_definition.rb` - Generate constructor function
2. `lib/stone/ast/constant_definition.rb` - Handle record binding specially
3. `lib/stone/ast/function_call.rb` - Remove record constructor special case
4. `lib/extensions/llvm_module.rb` - Update record type registration

## Files to Delete

1. `lib/stone/ast/record_instantiation.rb`

## Acceptance Criteria

- [ ] `Record(...)` returns a callable constructor function
- [ ] `Point(1, 2)` works via normal function call mechanism
- [ ] `AST::RecordInstantiation` class is deleted
- [ ] All existing record tests pass
- [ ] Record field access still works
- [ ] Record equality still works
- [ ] `make test` passes
- [ ] `make lint` passes

## Notes

- This change simplifies the AST and makes records more consistent with functional programming
- Constructor functions are first-class values that can be passed around
- This may enable future features like partial application of constructors
- The type system (Phase A) will need to handle "constructor function" types

## Relationship to Other Phases

- **Must complete before Phase A**: The type system needs to understand that record constructors are functions
- **Simplifies Phase A**: One less AST node type to handle in TypeChecker
- **Enables future features**: Higher-order constructor manipulation
