# Scope Data Structure

## Overview

Implement a `Scope` data structure to manage lexical scoping in Stone. Each scope tracks definitions (variables, type declarations) and has a reference to its parent scope for lookup chains. This is foundational for proper variable resolution, type declarations, and future features like closures.

## Prerequisites

- Basic compilation works (LLVM module, AST nodes)

## Goals

1. Create a `Stone::Scope` class to represent a lexical scope
2. Support nested scopes (block scopes, lambda scopes)
3. Provide lookup that chains through parent scopes
4. Integrate with compilation (pass scope through `to_llir`)

## Motivation

Currently, Stone uses the LLVM module extensions to store various registries:

- `record_types` - Record type definitions
- `record_instances` - Variables that hold record instances
- `function_aliases` - Named functions
- `string_constants` - String literal bindings

This approach has problems:

1. **No lexical scoping**: All definitions are global
2. **No shadowing**: Inner scopes can't shadow outer definitions
3. **No block scope**: Variables in blocks leak out
4. **Hard to extend**: Adding new definition types means more module methods

A proper `Scope` structure solves these issues and prepares for:

- Type declarations per scope
- Proper variable shadowing
- Block-scoped definitions
- Lambda closures

## Design

### Scope Class

```ruby
# lib/stone/scope.rb
module Stone
  class Scope
    attr_reader :parent, :definitions, :type_declarations

    def initialize(parent = nil)
      @parent = parent
      @definitions = {}          # name -> { value:, location: }
      @type_declarations = {}    # name -> { type_annotation:, location: }
    end

    # Create a child scope
    def child
      Scope.new(self)
    end

    # Define a name in this scope (also known as "binding")
    def define(name, value:, location: nil)
      @definitions[name] = { value:, location: }
    end

    # Register a type declaration in this scope
    def declare_type(name, type_annotation:, location: nil)
      @type_declarations[name] = { type_annotation:, location: }
    end

    # Look up a definition (chains through parents)
    def lookup(name)
      @definitions[name] || @parent&.lookup(name)
    end

    # Look up only in this scope (no parent chain)
    def lookup_local(name)
      @definitions[name]
    end

    # Look up a type declaration (chains through parents)
    def lookup_type_declaration(name)
      @type_declarations[name] || @parent&.lookup_type_declaration(name)
    end

    # Check if a name is defined in this scope (not parents)
    def defined_locally?(name)
      @definitions.key?(name)
    end

    # Check if a type is declared in this scope (not parents)
    def type_declared_locally?(name)
      @type_declarations.key?(name)
    end

    # Get the declared type annotation for a name
    def declared_type(name)
      decl = lookup_type_declaration(name)
      decl&.dig(:type_annotation)
    end

    # Get source location of a type declaration
    def type_declaration_location(name)
      decl = lookup_type_declaration(name)
      decl&.dig(:location)
    end

    # Depth of this scope (0 = top-level)
    def depth
      @parent ? @parent.depth + 1 : 0
    end

    # Is this the top-level scope?
    def top_level?
      @parent.nil?
    end

    # Get the top-level scope (singleton, memoized)
    def self.top_level
      @top_level ||= new
    end

    # Reset the top-level scope (for testing)
    def self.reset_top_level!
      @top_level = nil
    end
  end
end
```

### Shadowing Semantics

Enclosed scopes **shadow** outer definitions rather than mutating them:

```stone
x := 1
{
  x := 2    # This shadows outer x, does NOT mutate it
  x         # => 2
}
x           # => 1 (outer x unchanged)
```

This is the standard lexical scoping behavior. Each scope has its own namespace; defining a name in an inner scope creates a new definition that shadows the outer one.

### Integration with Compilation

Pass scope as a parameter to `to_llir` (explicit data flow):

```ruby
# Current signature:
def to_llir(builder, mod)

# New signature:
def to_llir(builder, mod, scope)
```

This requires updating every AST node's `to_llir` method, but provides:

- Explicit data flow (no hidden state)
- Clear scope at each compilation point
- Easier testing and reasoning

**Note**: We still need `mod` (LLVM module) for LLVM-specific operations:

- Creating LLVM functions
- Creating global variables
- Getting function references
- Managing string constants

The `scope` parameter handles language-level scoping; `mod` handles LLVM-level operations.

### Top-Level Scope

The top-level scope is a singleton accessed via `Stone::Scope.top_level`:

```ruby
# In ProgramUnit#to_llir
def to_llir(builder, mod, scope = Stone::Scope.top_level)
  @statements.each do |statement|
    statement.to_llir(builder, mod, scope)
  end

  # Return last expression value...
end
```

### Block and Lambda Scopes

Create child scopes by calling `scope.child`:

```ruby
# In Block#to_llir
def to_llir(builder, mod, scope)
  child_scope = scope.child

  @statements.each do |statement|
    statement.to_llir(builder, mod, child_scope)
  end
end

# In Lambda#to_llir
def to_llir(builder, mod, scope)
  child_scope = scope.child

  # Define parameters in child scope
  @parameters.each do |param|
    child_scope.define(param, value: ...)
  end

  # Process body with child scope
  @block.to_llir(builder, mod, child_scope)
end
```

## Implementation Steps

### Step 1: Create Scope Class

Create `lib/stone/scope.rb` with the structure shown above.

### Step 2: Update ProgramUnit

Start compilation with top-level scope:

```ruby
# In lib/stone/ast/program_unit.rb
def to_llir(builder, mod, scope = Stone::Scope.top_level)
  @statements.each do |statement|
    statement.to_llir(builder, mod, scope)
  end

  # Return last expression value...
end
```

### Step 3: Update All AST Nodes

Add `scope` parameter to every `to_llir` method:

```ruby
# Example: IntegerLiteral (doesn't use scope, but accepts it)
def to_llir(builder, mod, scope)
  LLVM::Int64.from_i(@value)
end

# Example: Reference (uses scope for lookup)
def to_llir(builder, mod, scope)
  definition = scope.lookup(identifier)

  if definition
    definition[:value]
  else
    # Fall back to existing lookup methods for now...
    mod.lookup_global(identifier) || mod.lookup_function(identifier)
  end
end
```

### Step 4: Update Block and Lambda

Create child scopes:

```ruby
# In Block#to_llir
def to_llir(builder, mod, scope)
  child_scope = scope.child

  last_value = nil
  @statements.each do |stmt|
    last_value = stmt.to_llir(builder, mod, child_scope)
  end
  last_value
end
```

### Step 5: Update ConstantDefinition

Register definitions in current scope:

```ruby
# In ConstantDefinition#to_llir
def to_llir(builder, mod, scope)
  llvm_value = value_expression.to_llir(builder, mod, scope)

  scope.define(identifier, value: llvm_value, location: location)

  # ... existing LLVM operations ...
end
```

## Migration Strategy

This is a significant change requiring updates to all AST nodes:

1. **Phase 1**: Create Scope class with tests
2. **Phase 2**: Update `to_llir` signatures (add scope parameter with default)
3. **Phase 3**: Update AST nodes one by one, keeping tests passing
4. **Phase 4**: Migrate type declarations to use Scope
5. **Phase 5**: Migrate other registries to use Scope
6. **Phase 6**: Remove redundant module extension methods

Use default parameter `scope = Stone::Scope.top_level` during migration to avoid breaking existing code.

## Test Cases

```ruby
RSpec.describe Stone::Scope do
  describe "basic operations" do
    it "creates an empty scope" do
      scope = Stone::Scope.new
      expect(scope.parent).to be_nil
      expect(scope.top_level?).to be true
    end

    it "defines and looks up values" do
      scope = Stone::Scope.new
      scope.define("x", value: 42)

      definition = scope.lookup("x")
      expect(definition[:value]).to eq(42)
    end

    it "returns nil for undefined names" do
      scope = Stone::Scope.new
      expect(scope.lookup("unknown")).to be_nil
    end

    it "tracks source locations" do
      scope = Stone::Scope.new
      scope.define("x", value: 42, location: { line: 1, column: 5 })

      definition = scope.lookup("x")
      expect(definition[:location]).to eq({ line: 1, column: 5 })
    end
  end

  describe "nested scopes" do
    it "creates child scopes" do
      parent = Stone::Scope.new
      child = parent.child

      expect(child.parent).to eq(parent)
      expect(child.depth).to eq(1)
    end

    it "looks up through parent chain" do
      parent = Stone::Scope.new
      parent.define("x", value: 42)

      child = parent.child
      definition = child.lookup("x")

      expect(definition[:value]).to eq(42)
    end

    it "shadows parent definitions" do
      parent = Stone::Scope.new
      parent.define("x", value: 1)

      child = parent.child
      child.define("x", value: 2)

      expect(child.lookup("x")[:value]).to eq(2)
      expect(parent.lookup("x")[:value]).to eq(1)
    end

    it "distinguishes local from inherited definitions" do
      parent = Stone::Scope.new
      parent.define("x", value: 1)

      child = parent.child

      expect(child.defined_locally?("x")).to be false
      expect(child.lookup("x")).not_to be_nil
    end
  end

  describe "type declarations" do
    it "declares and looks up types" do
      scope = Stone::Scope.new
      scope.declare_type("x", type_annotation: "Int", location: { line: 1, column: 1 })

      expect(scope.declared_type("x")).to eq("Int")
      expect(scope.type_declaration_location("x")).to eq({ line: 1, column: 1 })
    end

    it "looks up type declarations through parent chain" do
      parent = Stone::Scope.new
      parent.declare_type("x", type_annotation: "Int")

      child = parent.child
      expect(child.declared_type("x")).to eq("Int")
    end
  end

  describe "top-level scope" do
    before { Stone::Scope.reset_top_level! }

    it "returns the same instance" do
      expect(Stone::Scope.top_level).to equal(Stone::Scope.top_level)
    end

    it "is a top-level scope" do
      expect(Stone::Scope.top_level.top_level?).to be true
    end
  end
end

RSpec.describe "Scope integration" do
  it "shadows definitions in blocks" do
    code = <<~STONE
      x := 1
      { x := 2 }
      x
    STONE
    # Inner x shadows outer x; outer x unchanged
    expect(Stone.eval(code)).to eq(1)
  end

  it "creates child scope for lambdas" do
    code = <<~STONE
      x := 1
      f := λ(x) { x * 2 }
      f(21)
    STONE
    expect(Stone.eval(code)).to eq(42)
  end

  it "preserves outer scope after block" do
    code = <<~STONE
      x := 1
      y := { x := 10; x }
      x
    STONE
    # y captures inner x (10), but outer x is still 1
    expect(Stone.eval(code)).to eq(1)
  end
end
```

## Files to Create

1. `lib/stone/scope.rb` - Scope class implementation
2. `spec/unit/scope_spec.rb` - Unit tests for Scope

## Files to Modify

1. `lib/stone/ast/*.rb` - Add scope parameter to all `to_llir` methods
2. `lib/stone.rb` - Require scope.rb

## Acceptance Criteria

- [ ] `Stone::Scope` class exists with define/lookup methods
- [ ] `Stone::Scope.top_level` returns memoized singleton
- [ ] Scopes can be nested with parent references
- [ ] Lookup chains through parent scopes
- [ ] Inner scopes shadow outer definitions (not mutate)
- [ ] Type declarations can be stored in scope
- [ ] Source locations are preserved in definitions
- [ ] All `to_llir` methods accept scope parameter
- [ ] Existing tests continue to pass
- [ ] `make test` passes
- [ ] `make lint` passes

## Relationship to Other Features

### Prerequisites

- Basic compilation works

### Enables

- Type declaration tracking (scoped)
- Proper variable shadowing
- Block-scoped definitions
- Lambda closures
- Type annotation scoping (for generics)

## Notes

- This is foundational infrastructure - take care to get it right
- Use default parameter during migration to avoid breaking changes
- Source locations should come from AST nodes (parser provides these)
- Shadowing is the correct semantics - enclosed scopes do NOT mutate outer scopes
- Consider making Scope immutable in the future (functional style)
