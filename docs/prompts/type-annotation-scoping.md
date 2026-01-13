# Type Annotation Scoping

## Overview

Implement proper scoping for type annotations so that type references in annotations (the right side of `::`) can resolve identifiers from enclosing scopes. This is essential for generic types where type parameters like `T` need to be referenced in field type annotations.

## Prerequisites

- Basic type annotations work (`x :: Int`)
- Lambda parameter scoping works for value-level references

## Goals

1. Type annotations resolve type names from enclosing scope
2. Lambda parameters can be referenced in type annotations within the lambda body
3. `λ(T) { Record(first :: T) }` correctly binds T in the annotation
4. Proper error messages when type references cannot be resolved

## Motivation

Currently, type annotations like `first :: Int` treat the type name as a literal string. For generics to work, we need:

```stone
List := λ(T) { Record(first :: T, rest :: List(T)) }
#                           ^^^            ^^^
#                     These T's must resolve to the lambda parameter T
```

## Design Decisions

### Implementation Decisions (Resolved)

These decisions were made during implementation planning:

1. **Scope Integration**: Extend the existing `Stone::Scope` class rather than creating a separate `TypeScope`. The existing Scope already tracks type declarations and has parent/child chains.

2. **Type Representation**: Focus on simple type references for now (resolving `T` from lambda scope). Type application syntax (`List(T)`) will be a separate feature. Types should eventually be `Stone::Type` objects, but the infrastructure isn't fully in place yet.

3. **Resolution Timing**: Type resolution happens during LLIR generation, when scopes are built and available.

4. **Lambda Parameters**: Bind ALL lambda parameters in scope (not just uppercase ones). In Stone's unified namespace, types and values share the same space.

5. **Error Handling**: Raise `Stone::TypeError` for unknown types (new error class).

### Single Namespace for Types and Values

Types and values share the same namespace. This means:

- `T` in a lambda parameter is the same `T` referenced in type annotations
- Shadowing works normally (inner scope shadows outer)
- For implicit type parameters, warn when shadowed

### Type References vs Type Literals

In `first :: T`:

- `Int`, `Bool`, `String` are built-in type literals (always resolve)
- `T` is a type reference that must be looked up in scope
- `List(T)` is a type application (function call at type level)

### Scope Chain for Type Resolution

When resolving a type name:

1. Check current scope (lambda parameters, local bindings)
2. Check enclosing scopes (outer lambdas)
3. Check global types (Int, Bool, String, Type, user-defined records)
4. Error if not found

## Implementation Steps

### Step 1: Update TypeAnnotation to Support References

```ruby
# lib/stone/ast/type_annotation.rb
module Stone
  class AST
    class TypeAnnotation < Stone::AST

      attr_reader :type_expression

      def initialize(type_expression)
        @type_expression = type_expression  # Can be a name, reference, or application
        @name = :type_annotation
      end

      def resolve(scope)
        case @type_expression
        when String
          resolve_type_name(@type_expression, scope)
        when AST::Reference
          resolve_type_reference(@type_expression, scope)
        when AST::FunctionCall
          resolve_type_application(@type_expression, scope)
        else
          fail "Unknown type expression: #{@type_expression.class}"
        end
      end

      private def resolve_type_name(name, scope)
        # Built-in types
        return Stone::Type::Int if name == "Int"
        return Stone::Type::Bool if name == "Bool"
        return Stone::Type::String if name == "String"
        return Stone::Type::Type if name == "Type"
        return Stone::Type::Null if name == "Null"

        # Look up in scope
        scope.lookup_type(name) || fail(Stone::TypeError, "Unknown type: #{name}")
      end

      private def resolve_type_reference(ref, scope)
        resolve_type_name(ref.identifier, scope)
      end

      private def resolve_type_application(call, scope)
        # For List(T), resolve List and T, then apply
        # This is for generic type instantiation
        base_type = resolve_type_name(call.function_name, scope)
        arg_types = call.arguments.map { |arg| resolve(arg, scope) }
        base_type.apply(arg_types)
      end
    end
  end
end
```

### Step 2: Create Type Scope

```ruby
# lib/stone/type_scope.rb
module Stone
  class TypeScope
    def initialize(parent = nil)
      @parent = parent
      @bindings = {}
    end

    def bind(name, type)
      @bindings[name] = type
    end

    def lookup_type(name)
      @bindings[name] || @parent&.lookup_type(name)
    end

    def child_scope
      TypeScope.new(self)
    end
  end
end
```

### Step 3: Update Lambda to Create Type Scope

```ruby
# In lib/stone/ast/lambda.rb
def to_llir(_builder, mod)
  # Create a type scope for this lambda's parameters
  type_scope = mod.current_type_scope&.child_scope || TypeScope.new

  # Bind parameters as potential type variables
  # (They could be types if this is a type-level lambda)
  @parameters.each do |param|
    # For now, assume uppercase = type parameter
    if param.match?(/^[A-Z]/)
      type_scope.bind(param, TypeVariable.new(param))
    end
  end

  # Compile body with this type scope
  with_type_scope(mod, type_scope) do
    # ... existing compilation logic
  end
end
```

### Step 4: Update RecordDefinition to Use Type Scope

```ruby
# In lib/stone/ast/record_definition.rb
def to_llir(builder, mod)
  # Resolve field types using current type scope
  resolved_fields = @fields.map do |field|
    type = resolve_field_type(field[:type], mod.current_type_scope)
    { name: field[:name], type: type }
  end

  # Generate constructor with resolved types
  generate_constructor_function(mod, resolved_fields)
end

private def resolve_field_type(type_annotation, scope)
  if type_annotation.is_a?(String)
    # Simple type name - resolve it
    scope&.lookup_type(type_annotation) || lookup_builtin_type(type_annotation)
  else
    # Complex type expression - resolve recursively
    type_annotation.resolve(scope)
  end
end
```

### Step 5: Update Transform to Preserve Type References

```ruby
# In lib/stone/transform.rb
# When extracting type names from type_annotation nodes,
# preserve them as references that can be resolved later

private def extract_type_from_annotation(node)
  # Instead of just returning the string, return a structure
  # that can be resolved in context
  type_name = extract_type_name_string(node)

  # Check if it looks like a type application: List(T)
  if type_application?(node)
    extract_type_application(node)
  else
    type_name  # Simple name, will be resolved in scope
  end
end
```

## Test Cases

```ruby
RSpec.describe "Type Annotation Scoping" do
  describe "built-in types" do
    it "resolves Int in annotations" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        p := Point(1, 2)
        p.x
      STONE
      expect(Stone.eval(code)).to eq(1)
    end
  end

  describe "type parameters in lambdas" do
    it "resolves T from lambda parameter in record field" do
      code = <<~STONE
        Box := λ(T) { Record(value :: T) }
        Box
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end

    # Note: Nested type expressions like List(T) are out of scope for this PR
    # They will be implemented as part of generic type application

    it "errors on undefined type reference" do
      code = <<~STONE
        Bad := Record(value :: UndefinedType)
      STONE
      expect { Stone.eval(code) }.to raise_error(Stone::TypeError, /Unknown type/)
    end
  end

  describe "shadowing" do
    it "inner scope shadows outer scope" do
      code = <<~STONE
        T := Int
        outer := Record(x :: T)
        makeBox := λ(T) { Record(value :: T) }
        makeBox
      STONE
      # T inside lambda refers to lambda param, not outer T
      expect { Stone.eval(code) }.not_to raise_error
    end
  end

  describe "scope chain" do
    it "can reference types from outer scope" do
      code = <<~STONE
        ElementType := Int
        List := Record(first :: ElementType, rest :: List)
        List
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end
  end
end
```

## Files to Create

1. `lib/stone/type_error.rb` - Custom error class for type resolution failures
2. `spec/language/types/type_annotation_scoping_spec.rb` - Integration tests

## Files to Modify

1. `lib/stone/scope.rb` - Add `lookup_type` method for type name resolution
2. `lib/stone/ast/type_annotation.rb` - Add resolution logic
3. `lib/stone/ast/lambda.rb` - Bind parameters in scope for type resolution
4. `lib/stone/ast/record_definition.rb` - Use scope when resolving field types
5. `lib/stone.rb` - Require new type_error file

## Acceptance Criteria

- [ ] `λ(T) { Record(value :: T) }` compiles without error
- [ ] T in annotation resolves to lambda parameter T
- [ ] Built-in types (Int, Bool, String) always resolve
- [ ] Unknown type names produce clear error messages
- [ ] Shadowing works correctly
- [ ] Nested scopes resolve correctly
- [ ] All existing tests pass
- [ ] `make test` passes
- [ ] `make lint` passes

## Relationship to Other Features

### Prerequisites

- Basic type annotations
- Lambda parameter scoping (for values)

### Enables

- Generic types (`List := λ(T) { Record(...) }`)
- Type-level functions
- Recursive generic types

### Future Enhancements

- Type inference
- Type constraints
- Explicit type parameter syntax in lambdas

## Notes

- This is foundational for generics - without it, T in type annotations is meaningless
- The single namespace for types and values keeps things simple
- Uppercase convention for type params helps readability but isn't enforced
- Type resolution happens at compile time, not runtime
