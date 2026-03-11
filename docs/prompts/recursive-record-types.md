# Recursive Record Types

## Overview

Implement support for recursive record types in Stone, where a record type can reference itself in its field definitions. This is essential for defining data structures like linked lists, trees, and other recursive structures.

## Prerequisites

- Record types work (`Record(x :: Int, y :: Int)`)
- NULL literal implemented (for terminating recursive structures)
- Type annotation scoping (for resolving type references)

## Goals

1. Allow record types to reference themselves: `IntList := Record(first :: Int, rest :: IntList)`
2. Use pointers (stored as i64) for recursive fields to avoid infinite struct size
3. NULL can be used to terminate recursive structures
4. Property access works on recursive fields (load from pointer)
5. Nested access works: `list.rest.first`

## Motivation

Without recursive types, we cannot define fundamental data structures:

```stone
# This should work:
IntList := Record(first :: Int, rest :: IntList)
list := IntList(1, IntList(2, IntList(3, NULL)))
list.rest.first  # Should return 2
```

## Design Decisions

### Recursive Fields as Pointers

Recursive fields are stored as i64 (pointer cast to integer):

- Avoids infinite struct size
- Compatible with NULL (which is 0)
- Requires pointer-to-struct conversion on access

```llvm
; IntList in LLVM:
%IntList = type { i64, i64 }  ; { first :: Int, rest :: pointer-as-i64 }
```

### Detection of Recursive References

A field type is recursive if:

1. It exactly matches the record type being defined
2. Or it's a type application involving the record type being defined (for generics)

### Property Access on Recursive Fields

When accessing a recursive field:

1. Extract the i64 value from the struct
2. If the field type is recursive, cast i64 to pointer
3. Load the struct from the pointer
4. Extract the requested field

## Implementation Steps

### Step 1: Track Type Name in RecordDefinition

```ruby
# In lib/stone/ast/record_definition.rb
class RecordDefinition < Stone::AST
  attr_reader :fields
  attr_accessor :type_name  # Set by ConstantDefinition

  def initialize(fields)
    @fields = fields
    @type_name = nil  # Will be set when assigned to a name
  end
  
  def recursive_field?(field)
    field[:type] == @type_name
  end
end
```

### Step 2: Update ConstantDefinition to Set Type Name

```ruby
# In lib/stone/ast/constant_definition.rb
def to_llir(builder, mod)
  # Set type_name on RecordDefinition for recursive type support
  if value_expression.is_a?(Stone::AST::RecordDefinition)
    value_expression.type_name = identifier
  end
  
  # ... rest of existing code
end
```

### Step 3: Update LLVM Type Generation for Recursive Fields

```ruby
# In lib/stone/ast/record_definition.rb
private def llvm_type_for(type_name, mod = nil)
  case type_name
  when "Int" then LLVM::Int64
  when "Bool" then LLVM::Int1
  when "String" then LLVM::Int64  # Pointer as i64
  else
    # Check if it's a recursive reference
    if type_name == @type_name
      # Recursive field - store as pointer (i64)
      LLVM::Int64
    elsif mod&.record_type?(type_name)
      # Reference to another record type - also use i64
      LLVM::Int64
    else
      fail "Unknown type: #{type_name}"
    end
  end
end
```

### Step 4: Update Constructor to Handle Recursive Arguments

The constructor needs to handle both NULL and record instances for recursive fields:

```ruby
# Constructor receives:
# - For NULL: i64 value 0
# - For nested record: i64 pointer to the record
# Both work because NULL is 0 and nested records are pointers cast to i64
```

### Step 5: Update PropertyAccess for Recursive Fields

```ruby
# In lib/stone/ast/property_access.rb
private def access_record_field(builder, mod)
  record_type_name = get_record_type_name(mod)
  record_def = lookup_record_definition(mod, record_type_name)
  field_index = get_field_index(record_def, record_type_name)

  # Evaluate the receiver to get the record struct
  receiver_value = @receiver.to_llir(builder, mod)

  # If receiver is an i64 (pointer to recursive field), load the struct first
  if receiver_value.type == LLVM::Int64.type
    struct_type = record_def.llvm_type(mod)
    struct_ptr = builder.int2ptr(receiver_value, LLVM::Type.pointer(struct_type), "struct_ptr")
    receiver_value = builder.load2(struct_type, struct_ptr, "loaded_struct")
  end

  # Extract the field value from the struct
  builder.extract_value(receiver_value, field_index, "#{@property}_value")
end
```

### Step 6: Update PropertyAccess Type Inference

```ruby
# In lib/stone/ast/property_access.rb
private def record_field_access?(mod)
  # Check if receiver is a Reference to a record instance
  return @receiver.record_instance?(mod) if @receiver.is_a?(Reference)

  # Check if receiver is a FunctionCall that returns a record
  return mod.record_type?(@receiver.function_name) if @receiver.is_a?(FunctionCall)

  # Check if receiver is a PropertyAccess that returns a record type
  if @receiver.is_a?(PropertyAccess)
    receiver_type = infer_type(@receiver, mod)
    return mod.record_type?(receiver_type) if receiver_type
  end

  false
end

private def lookup_record_field_type(receiver_type, property_name, mod)
  return nil unless mod && receiver_type && mod.record_type?(receiver_type)

  record_def = mod.record_types[receiver_type]
  return nil unless record_def

  field = record_def.fields.find { |f| f[:name] == property_name }
  field&.dig(:type)
end
```

## Test Cases

```ruby
RSpec.describe "Recursive Record Types" do
  describe "defining recursive types" do
    it "can define a recursive record type" do
      code = <<~STONE
        IntList := Record(first :: Int, rest :: IntList)
        IntList
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end

    it "can define a tree type" do
      code = <<~STONE
        Tree := Record(value :: Int, left :: Tree, right :: Tree)
        Tree
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end
  end

  describe "instantiating recursive types" do
    it "can create a single-element list with NULL terminator" do
      code = <<~STONE
        IntList := Record(first :: Int, rest :: IntList)
        list := IntList(42, NULL)
        list.first
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "can create a multi-element list" do
      code = <<~STONE
        IntList := Record(first :: Int, rest :: IntList)
        list := IntList(1, IntList(2, IntList(3, NULL)))
        list.first
      STONE
      expect(Stone.eval(code)).to eq(1)
    end
  end

  describe "accessing recursive fields" do
    it "can access the rest field" do
      code = <<~STONE
        IntList := Record(first :: Int, rest :: IntList)
        list := IntList(1, IntList(2, NULL))
        list.rest.first
      STONE
      expect(Stone.eval(code)).to eq(2)
    end

    it "can access deeply nested elements" do
      code = <<~STONE
        IntList := Record(first :: Int, rest :: IntList)
        list := IntList(1, IntList(2, IntList(3, NULL)))
        list.rest.rest.first
      STONE
      expect(Stone.eval(code)).to eq(3)
    end

    it "can check if rest is NULL" do
      code = <<~STONE
        IntList := Record(first :: Int, rest :: IntList)
        list := IntList(42, NULL)
        list.rest == NULL
      STONE
      expect(Stone.eval(code)).to be true
    end
  end

  describe "string lists" do
    it "can create a list of strings" do
      code = <<~STONE
        StringList := Record(first :: String, rest :: StringList)
        list := StringList("hello", StringList("world", NULL))
        list.first
      STONE
      expect(Stone.eval(code)).to eq("hello")
    end

    it "can access nested string elements" do
      code = <<~STONE
        StringList := Record(first :: String, rest :: StringList)
        list := StringList("hello", StringList("world", NULL))
        list.rest.first
      STONE
      expect(Stone.eval(code)).to eq("world")
    end
  end
end
```

## Files to Create

1. `spec/language/records/recursive_record_spec.rb` - Tests for recursive records

## Files to Modify

1. `lib/stone/ast/record_definition.rb` - Add type_name tracking, recursive field detection
2. `lib/stone/ast/constant_definition.rb` - Set type_name on RecordDefinition
3. `lib/stone/ast/property_access.rb` - Handle recursive field access (load from pointer)

## Acceptance Criteria

- [ ] `IntList := Record(first :: Int, rest :: IntList)` compiles
- [ ] `IntList(42, NULL)` creates a single-element list
- [ ] `list.first` returns the first element
- [ ] `list.rest.first` works for nested access
- [ ] `list.rest == NULL` works for checking termination
- [ ] Multiple levels of nesting work
- [ ] StringList works similarly
- [ ] All existing tests pass
- [ ] `make test` passes
- [ ] `make lint` passes

## Relationship to Other Features

### Prerequisites

- Record types (Phase 0)
- NULL literal
- Type annotation scoping (for resolving the self-reference)

### Enables

- Generic recursive types (List(T))
- Tree data structures
- Any self-referential data type

### Future Enhancements

- Pattern matching on recursive types
- Tail-call optimization for recursive operations
- Automatic derive of common operations (map, fold)

## Notes

- The key insight is storing recursive fields as i64 (pointer values)
- This avoids the "infinite struct size" problem
- NULL being 0 makes it naturally compatible with pointer fields
- Property access must detect and handle the pointer-to-struct conversion
- Nested access like `list.rest.rest.first` must chain these conversions
