# Type-Based Union Constructor Dispatch

## Overview

Union constructor calls should dispatch to the correct alternative based on
argument types, not field count. This enables unions with multiple Record
alternatives that have the same number of fields.

Ask any questions up front, as much as possible. Once your questions have been
answered, you may continue all the way to committing and wrap-up.

## Current State

Union instantiation currently matches alternatives by field count:

```ruby
# In FunctionCall#find_matching_record_alternative
match = union_type.find_record_alternative_by_field_count(arguments.length)
```

This works for simple unions where each Record alternative has a different
number of fields:

```stone
IntOption := Null | Record(value :: Int)
some := IntOption(42)   # 1 arg -> matches Record(value :: Int)
none := NULL            # Null alternative (but loses type info)
```

## Problem

Field-count matching breaks with multiple same-arity alternatives:

```stone
Result := Record(value :: Int) | Record(error :: String)
ok := Result(42)        # Should be Record(value :: Int)
err := Result("oops")   # Should be Record(error :: String)
# BROKEN: Both match the first 1-field Record found!
```

It also doesn't support explicit Null construction with type preservation:

```stone
List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
IntList := List(Int)
empty := IntList(NULL)  # What does this mean? 1-arg, no 1-field Record exists
```

## Proposed Design

### Type-Based Alternative Matching

When instantiating a union `UnionType(args...)`:

1. Evaluate each argument to get its Stone type
2. For each Record alternative in the union:
   - Check if argument count matches field count
   - Check if each argument type is compatible with the corresponding field type
3. Select the first alternative where all types match
4. Fail with a clear error if no alternative matches or multiple match ambiguously

### Null Alternative Construction

Support explicit Null construction via the union type:

```stone
empty := IntList()      # 0 args -> matches Null alternative
# empty has Stone type List(Int), not just Null
```

Or with explicit NULL argument:

```stone
empty := IntList(NULL)  # Special case: NULL matches Null alternative
```

### Type Compatibility Rules

For matching argument types to field types:

- Exact match: `Int` argument matches `Int` field
- Subtype: Argument type is subtype of field type (future: when subtyping exists)
- Union member: Argument type is an alternative of a union field type
- Null: `NULL` literal matches `Null` alternative or nullable field types

## Test Cases

```ruby
RSpec.describe "Union constructor dispatch" do
  before { Stone::Scope.reset_top_level! }
  after { Stone::Scope.reset_top_level! }

  describe "same-arity alternatives" do
    it "dispatches based on argument type" do
      code = <<~STONE
        Result := Record(value :: Int) | Record(error :: String)
        ok := Result(42)
        ok.value
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "matches String argument to String field" do
      code = <<~STONE
        Result := Record(value :: Int) | Record(error :: String)
        err := Result("oops")
        err.error
      STONE
      expect(Stone.eval(code)).to eq("oops")
    end

    it "fails when argument type matches no alternative" do
      code = <<~STONE
        Result := Record(value :: Int) | Record(error :: String)
        Result(TRUE)
      STONE
      expect { Stone.eval(code) }.to raise_error(Stone::TypeError, /no matching.*alternative/i)
    end
  end

  describe "null alternative construction" do
    it "constructs Null alternative with zero arguments" do
      code = <<~STONE
        IntOption := Null | Record(value :: Int)
        none := IntOption()
        none == NULL
      STONE
      expect(Stone.eval(code)).to be true
    end

    it "preserves union type for empty list" do
      code = <<~STONE
        List :: (Type) -> Type
        List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
        IntList := List(Int)
        List@empty? :: (List) -> Bool
        List@empty? := λ(list) { list == NULL }
        empty := IntList()
        empty.empty?
      STONE
      expect(Stone.eval(code)).to be true
    end
  end

  describe "backwards compatibility" do
    it "still works with different-arity alternatives" do
      code = <<~STONE
        Point := Record(x :: Int) | Record(x :: Int, y :: Int)
        p1 := Point(1)
        p2 := Point(2, 3)
        +(p1.x, p2.y)
      STONE
      expect(Stone.eval(code)).to eq(4)
    end
  end
end
```

## Implementation Steps

### Step 0: Write tests

Follow TDD; write all the tests first. Mark all newly added tests as pending
initially; remove the pending flag as you attempt to pass each one.

### Step 1: Add type inference for arguments

In `FunctionCall`, before matching alternatives, evaluate argument types:

```ruby
private def infer_argument_types(context)
  arguments.map { |arg| arg.type(context) }
end
```

### Step 2: Implement type-based matching

Replace `find_matching_record_alternative` with type-aware matching:

```ruby
private def find_matching_alternative(union_type, arg_types)
  # Handle zero-arg case (Null alternative)
  return null_alternative(union_type) if arg_types.empty?

  # Find Record alternative with matching field types
  union_type.alternatives.find do |alt|
    next false unless alt.record?
    next false unless alt.fields.length == arg_types.length

    fields_match_types?(alt.fields, arg_types)
  end
end

private def fields_match_types?(fields, arg_types)
  fields.zip(arg_types).all? do |field, arg_type|
    field_type_compatible?(field, arg_type)
  end
end
```

### Step 3: Implement type compatibility

```ruby
private def field_type_compatible?(field, arg_type)
  field_type = field.resolve_type
  return true if field_type == arg_type
  return true if arg_type&.name == "Null" && field_type&.nullable?
  # Add more compatibility rules as needed

  false
end
```

### Step 4: Handle Null alternative explicitly

Support `UnionType()` with zero arguments to construct the Null alternative:

```ruby
private def null_alternative(union_type)
  union_type.alternatives.find { |alt| alt.name == "Null" }
end
```

### Step 5: Track union type in scope

When constructing via `IntList()`, ensure the result has Stone type `List(Int)`
in scope, not just `Null`. This enables computed property lookup on the generic
base name.

### Step 6: Update error messages

Provide clear errors when:

- No alternative matches the argument types
- Multiple alternatives match ambiguously (future concern)

## Files to Modify

1. `lib/stone/ast/function_call.rb` - `instantiate_union`, `find_matching_record_alternative`
2. `lib/stone/type.rb` - May need `Union#find_alternative_by_types`
3. `lib/stone/ast/constant_definition.rb` - Track union type for null constructions
4. `spec/language/types/sum_type_spec.rb` - Add new tests

## Acceptance Criteria

- [ ] Same-arity Record alternatives dispatch correctly by type
- [ ] `UnionType()` with zero args constructs the Null alternative
- [ ] Null alternative preserves the union type for computed property lookup
- [ ] Clear error messages for type mismatches
- [ ] Existing field-count matching still works (backwards compatible)
- [ ] All existing tests pass
- [ ] `make test` passes
- [ ] `make lint` passes

## Relationship to Other Features

### Prerequisites

- Sum types (implemented)
- Type inference for literals (partially implemented)

### Enables

- Empty list construction with type preservation: `IntList()`
- Result types: `Result(value)` vs `Result(error)`
- More expressive union types in general

### Related

- Lambda parameter type generalization (in progress) - needed for computed
  properties on union types
- Type annotations on variables (future) - alternative way to specify types

## Wrap-Up

Once you've completed the implementation:

- Update this file with any as-built changes we made to the design
    - Don't overwrite original design decisions
- Include this updated file as part of the commit
- Add any lessons learned to your "memory"
- Run the `/retro` command
