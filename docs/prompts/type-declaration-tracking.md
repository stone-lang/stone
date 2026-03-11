# Type Declaration Tracking

## Overview

Implement tracking of type declarations so that every `x :: Type` declaration is stored in a scoped registry for later access.
This enables type checking, IDE support, and documentation generation.

## Prerequisites

- Basic type annotations work (`x :: Int` parses)
- Scope data structure (`scope-data-structure.md`) - provides scoped storage

## Goals

1. Transform `type_declaration` grammar nodes into `TypeDeclaration` AST nodes
2. Store statement-level type declarations in the current scope's registry
3. Process all type declarations in a scope before processing constant definitions
4. Retain source locations from AST for error messages
5. Provide lookup API: "What is the declared type of `x`?"

## Current State

The grammar already parses type declarations:

```ruby
rule(:type_declaration) { identifier + ws! + str("::") + ws! + type_annotation }
```

However:

- No transform exists for `type_declaration` - it's only used in `record_definition` for field extraction
- Type declarations are parsed but discarded
- No registry tracks declared types

## Desired State

```stone
double :: (Int) -> Int
double := λ(x) { x * 2 }

# Later, we can look up: scope.declared_type("double").to_s => "(Int) -> Int"
```

The type declaration should be stored in the current scope.

## Semantic Contexts

Type declarations (`x :: Type`) appear in two different contexts with different semantics:

### 1. Statement-Level Type Declarations

At statement level (top-level or inside a block), a type declaration registers the declared type for an identifier in the current scope:

```stone
x :: Int          # Statement: registers that x has type Int in current scope
x := 42           # Definition: assigns value to x
```

These type declarations:

- Are transformed to `TypeDeclaration` AST nodes
- Register in the current scope's type declaration registry
- Return `nil` (no value produced)
- **Only statement-level type declarations go in the registry**

### 2. Record Field Definitions

Inside a `Record(...)` definition, type declarations define **fields**:

```stone
Point := Record(x :: Int, y :: Int)
#               ^^^^^^^^  ^^^^^^^^
#               Field declarations, not statement-level type declarations
```

These are handled by the `RecordDefinition` transform, which extracts field names and types directly. They do NOT register in the type declaration registry.

### Grammar Implications

The current grammar has type_declaration as part of expression:

```ruby
rule(:expression) { type_declaration | comparison_operation | postfix_expression }
```

This works because:

- Expressions can be statements (top-level or in blocks)
- Record definitions extract type_declaration children specially

In practice, type declarations only make sense in these two contexts.
Using them elsewhere (like `foo(x :: Int)`) would be meaningless.

## Design Decisions

### Storage Location: Scope

Type declarations are stored in the `Scope` data structure, not in LLVM module extensions.
This enables:

- Per-scope type declarations (each block has its own scope)
- Proper shadowing (inner scope can redeclare types)
- Lookup through scope chain

```ruby
# In Stone::Scope (from scope-data-structure.md)
def declare_type(name, type_annotation:, location: nil)
  @type_declarations[name] = { type_annotation:, location: }
end

def declared_type(name)
  decl = lookup_type_declaration(name)
  decl&.dig(:type_annotation)
end
```

### Processing Order

Within each scope, **all type declarations must be processed before any constant definitions**. This ensures that when we process `x := 42`, we already know the declared type of `x`.

```stone
# These should work regardless of order in source:
x := 42
x :: Int

# Because we process as:
# 1. First pass: collect all type declarations in scope
# 2. Second pass: process all definitions and expressions
```

Implementation in `ProgramUnit` and `Block`:

```ruby
def to_llir(builder, mod, scope)
  # Phase 1: Register all type declarations first
  type_decls, other_stmts = @statements.partition { |s| s.is_a?(Stone::AST::TypeDeclaration) }

  type_decls.each do |td|
    scope.declare_type(td.identifier, type_annotation: td.type_annotation, location: td.location)
  end

  # Phase 2: Process all other statements
  other_stmts.each { |s| s.to_llir(builder, mod, scope) }
end
```

### Type Annotation Representation

For now, `type_annotation` is stored as a **string**.
In the near future (with function types), it will be stored as a `Stone::Type` subclass instance.

```ruby
# Current (this prompt):
scope.declare_type("x", type_annotation: "Int", location: loc)

# Future (after function-type-syntax.md):
scope.declare_type("x", type_annotation: Stone::Type::Int, location: loc)
```

### Source Location Tracking

Type declarations retain their source location from the AST for error messages:

```ruby
class TypeDeclaration < Stone::AST
  attr_reader :identifier, :type_annotation, :location

  def initialize(identifier, type_annotation, location: nil)
    @identifier = identifier
    @type_annotation = type_annotation
    @location = location  # { line:, column: } from parser
    @name = :type_declaration
  end
end
```

This enables error messages like:

```text
Type error at line 5, column 3:
  x was declared as Int (at line 1, column 1) but assigned String
```

### TypeDeclaration AST Node

The `TypeDeclaration` AST node is a **pure data class** - it holds the identifier, type annotation, and source location but does not generate LLVM IR. Registration in the scope is handled by `ProgramUnit` and `Block` during two-phase processing.

This design is intentional: type declarations are a compile-time construct with no runtime representation. The `to_llir` method would be misleading since it wouldn't actually generate any IR.

## Implementation Steps

### Step 1: Add Transform for type_declaration

```ruby
# In lib/stone/transform.rb
require "stone/ast/type_declaration"

transform(:type_declaration) do |node|
  identifier = extract_field_name(node)  # Reuse existing method
  type_annotation = extract_type_name(node)  # Reuse existing method
  location = extract_location(node)

  Stone::AST::TypeDeclaration.new(identifier, type_annotation, location:)
end

private def extract_location(node)
  return nil unless node.respond_to?(:start_location)

  loc = node.start_location
  { line: loc.line, column: loc.column }
end
```

### Step 2: Update TypeDeclaration AST Node

```ruby
# lib/stone/ast/type_declaration.rb
require "stone/ast"

module Stone
  class AST
    class TypeDeclaration < Stone::AST
      attr_reader :identifier, :type_annotation, :location

      def initialize(identifier, type_annotation, location: nil)
        @identifier = identifier
        @type_annotation = type_annotation
        @location = location
        @name = :type_declaration
      end

      def to_s
        "#{identifier} :: #{type_annotation}"
      end
    end
  end
end
```

Note: `TypeDeclaration` is a pure data class with no `to_llir` method. Registration is handled by `ProgramUnit` and `Block`.

### Step 3: Update TopFunction for Two-Phase Processing

The actual statement processing happens in `TopFunction#compile_children`, not directly in `ProgramUnit`:

```ruby
# In lib/stone/ast/program_unit/top_function.rb
private def compile_children(builder, mod, scope)
  children = @children&.compact || []

  # Phase 1: Register all type declarations first
  type_decls, other_stmts = children.partition { |c| c.is_a?(Stone::AST::TypeDeclaration) }

  type_decls.each do |td|
    scope.declare_type(td.identifier, type_annotation: td.type_annotation, location: td.location)
  end

  # Phase 2: Process all other statements that respond to to_llir
  other_stmts.select { |child| child.respond_to?(:to_llir) }.map { |child| child.to_llir(builder, mod, scope) }
end
```

### Step 4: Update Block for Two-Phase Processing

The statement processing happens in `Block#evaluate_body_and_return`:

```ruby
# In lib/stone/ast/block.rb
def evaluate_body_and_return(builder, mod, scope)
  child_scope = scope.child
  stmts = Array(statements).compact

  # Phase 1: Register type declarations first
  type_decls, other_stmts = stmts.partition { |s| s.is_a?(Stone::AST::TypeDeclaration) }

  type_decls.each do |td|
    child_scope.declare_type(td.identifier, type_annotation: td.type_annotation, location: td.location)
  end

  # Phase 2: Process other statements
  results = other_stmts.map { |stmt| stmt.to_llir(builder, mod, child_scope) }
  last_result = results.compact.last || LLVM::Int64.from_i(0)
  builder.ret(last_result)
end
```

## Test Cases

```ruby
RSpec.describe "Type Declaration Tracking" do
  describe "parsing" do
    it "parses type declaration as statement" do
      expect("x :: Int").to parse_as(:statement)
    end

    it "parses type declaration in a program" do
      code = <<~STONE
        x :: Int
        x := 42
      STONE
      expect { Stone.parse(code) }.not_to raise_error
    end
  end

  describe "registration in scope" do
    it "registers type declaration in current scope" do
      code = <<~STONE
        x :: Int
        x := 42
        x
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "stores the declared type for lookup" do
      code = <<~STONE
        answer :: Int
        answer := 42
        answer
      STONE
      result, scope = Stone.eval_with_scope(code)
      expect(scope.declared_type("answer")).to eq("Int")
    end

    it "handles multiple type declarations" do
      code = <<~STONE
        x :: Int
        y :: Bool
        x := 42
        y := TRUE
        x
      STONE
      result, scope = Stone.eval_with_scope(code)
      expect(scope.declared_type("x")).to eq("Int")
      expect(scope.declared_type("y")).to eq("Bool")
    end

    it "retains source location" do
      code = <<~STONE
        answer :: Int
        answer := 42
        answer
      STONE
      result, scope = Stone.eval_with_scope(code)
      location = scope.type_declaration_location("answer")
      expect(location[:line]).to eq(1)
    end
  end

  describe "processing order" do
    it "processes type declarations before definitions" do
      code = <<~STONE
        x := 42
        x :: Int
        x
      STONE
      result, scope = Stone.eval_with_scope(code)
      # Type declaration should be available even though it appears after definition
      expect(scope.declared_type("x")).to eq("Int")
    end
  end

  describe "scoped declarations" do
    it "type declarations in blocks are scoped" do
      code = <<~STONE
        x :: Int
        x := 1
        {
          y :: Bool
          y := TRUE
          y
        }
        x
      STONE
      result, scope = Stone.eval_with_scope(code)
      expect(scope.declared_type("x")).to eq("Int")
      expect(scope.declared_type("y")).to be_nil  # y is in inner scope
    end

    it "inner scope can shadow outer type declarations" do
      code = <<~STONE
        x :: Int
        x := 1
        {
          x :: Bool
          x := TRUE
          x
        }
      STONE
      # Should not error - inner scope shadows outer
      expect { Stone.eval(code) }.not_to raise_error
    end
  end

  describe "with record types" do
    it "tracks record type declarations" do
      code = <<~STONE
        Point :: Type
        Point := Record(x :: Int, y :: Int)
        Point
      STONE
      result, scope = Stone.eval_with_scope(code)
      expect(scope.declared_type("Point")).to eq("Type")
    end

    it "does not register record field declarations" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        Point
      STONE
      result, scope = Stone.eval_with_scope(code)
      # x and y are field declarations, not statement-level
      expect(scope.declared_type("x")).to be_nil
      expect(scope.declared_type("y")).to be_nil
    end
  end

  describe "without declaration" do
    it "returns nil for undeclared identifiers" do
      code = <<~STONE
        x := 42
        x
      STONE
      result, scope = Stone.eval_with_scope(code)
      expect(scope.declared_type("x")).to be_nil
    end
  end
end
```

## Files to Create

1. `spec/language/types/type_declaration_tracking_spec.rb` - Integration tests

## Files to Modify

1. `lib/stone/transform.rb` - Add transform for `type_declaration` with location
2. `lib/stone/ast/type_declaration.rb` - Add location attribute (pure data class, no `to_llir`)
3. `lib/stone/ast/program_unit/top_function.rb` - Two-phase processing in `compile_children`
4. `lib/stone/ast/block.rb` - Two-phase processing in `evaluate_body_and_return`
5. `lib/stone.rb` - Add `eval_with_scope` method for testing

**Note:** `lib/stone/scope.rb` already has the required methods (`declare_type`, `declared_type`, `type_declaration_location`, `lookup_type_declaration`) - no changes needed.

## Acceptance Criteria

- [ ] `type_declaration` nodes are transformed to `TypeDeclaration` AST
- [ ] Statement-level type declarations are stored in current scope
- [ ] Record field declarations do NOT register in scope
- [ ] Type declarations are processed before constant definitions
- [ ] Source locations are preserved in type declarations
- [ ] `scope.declared_type("x")` returns the type annotation string
- [ ] `scope.type_declaration_location("x")` returns source location
- [ ] Inner scopes can shadow outer type declarations
- [ ] Multiple type declarations are all tracked
- [ ] Undeclared identifiers return `nil`
- [ ] All existing tests pass
- [ ] `make test` passes
- [ ] `make lint` passes

## Relationship to Other Features

### Prerequisites

- Basic type annotations (parsing)
- Scope data structure (`scope-data-structure.md`)

### Enables

- Function type syntax (type annotations become AST nodes)
- Type checking arguments (lookup declared types)
- IDE support (show types on hover)
- Documentation generation

### Future Enhancements

- Warn on duplicate type declarations in same scope
- Warn when declaration doesn't match inferred type
- Store `Stone::Type` instances instead of strings
- Type declaration without definition (forward declarations)

## Notes

- Only **statement-level** type declarations go in the scope registry
- Record field declarations are handled separately by `RecordDefinition`
- Type annotations are stored as **strings for now**; will become `Stone::Type` subclasses
- Source locations enable better error messages
- Two-phase processing ensures declarations are available before definitions
- This is foundational for function type syntax and type checking
