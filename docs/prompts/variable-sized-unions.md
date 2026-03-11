# Variable-Sized Union Payloads

## Status: IMPLEMENTED

Implemented in commits:

- `9131c9a` - Implement variable-sized union payloads (CHERI-safe)
- `1669199` - Implement multi-type unions (Int | String) without ptr2int
- `d587c69` - Implement chained property access on union fields

## Overview

Refactor union type representation to use variable-sized payloads
instead of fixed i64.
The payload size is determined by the largest alternative type
(similar to Rust's enum representation).

## Previous Implementation

```llvm
%my_union_type = type { ptr, i64 }  ; type_tag, fixed 64-bit payload
```

Problems:

- Can't hold values larger than 64 bits (i128, f128, Decimal128, IPv6, UUID)
- Uses `ptr2int`/`int2ptr` which breaks on some CPU designs (such as CHERI)
- Requires heap allocation for structs larger than 8 bytes

## Current Implementation

```llvm
; Payload sized to largest alternative, using {ptr, [N x i8]} struct
%my_union_int_null = type { ptr, [8 x i8] }       ; max(8, 0) = 8 bytes
%my_union_i128_str = type { ptr, [16 x i8] }      ; max(16, 8) = 16 bytes
```

### Union Type Categories

The implementation distinguishes between two categories of unions:

1. **Homogeneous unions** - All non-null alternatives have the same LLVM type kind
   (all pointers OR all integers). These use phi-merge extraction.

2. **Mixed-type unions** - Alternatives have different LLVM type kinds
   (e.g., `Int | String` mixes integer and pointer). These return the raw
   payload as i64 and use Ruby-side type dispatch via `MixedUnionValueConverter`.

### Key Methods

```ruby
# In lib/stone/type.rb - Union class

def homogeneous?
  # True if all non-null alternatives have the same LLVM type kind
  non_null = @alternatives.reject { |t| null_type?(t) }
  return true if non_null.size <= 1
  first_kind = non_null.first.llvm_type.kind
  non_null.all? { |t| t.llvm_type.kind == first_kind }
end

def common_llvm_result_type
  # For homogeneous unions: returns the common type (ptr or i64)
  # For mixed unions: returns nil (caller handles specially)
end

def property_return_type(property_name)
  # Look through non-null alternatives for property access
  # Enables chained access like `o.value.x` where `value` is `Point | Null`
end
```

### Payload Storage (No ptr2int)

```ruby
# In lib/stone/ast/record_instantiation.rb

private def store_payload(builder, payload_ptr, llvm_value, _value_type)
  # Direct store - no ptr2int conversion (CHERI-safe)
  builder.store(llvm_value, payload_ptr)
end
```

### Payload Extraction

```ruby
# In lib/stone/ast/property_access.rb

private def extract_union_payload(builder, mod, union_value, union_type)
  # For homogeneous unions, extract with phi merge
  return extract_homogeneous_union(...) if union_type.homogeneous?

  # For mixed-type unions, extract payload as i64
  # Ruby-side MixedUnionValueConverter handles type dispatch
  extract_mixed_union_payload(...)
end

private def extract_homogeneous_union(builder, mod, union_value, union_type)
  # Uses phi-merge with multiple basic blocks:
  # - One block per non-null alternative
  # - Null block returns appropriate zero value
  # No int2ptr or ptr2int conversions (CHERI-safe)
end
```

### Chained Property Access

Enables expressions like `o.value.x` where `value` is `Point | Null`:

```ruby
# In lib/stone/ast/property_access.rb

private def receiver_is_union_with_record?(mod)
  receiver_type = safe_get_receiver_type(mod)
  return false unless receiver_type&.union?

  receiver_type.alternatives.any? do |alt|
    next false if alt.name == "Null"
    alt.record? && alt.property_return_type(@property)
  end
end

private def access_field_on_union_record(builder, mod, scope)
  # The receiver's to_llir already extracts the record pointer
  # We just load the struct and access the field
  record_ptr = @receiver.to_llir(builder, mod, scope)
  record_struct = builder.load2(record_def.llvm_type(mod), record_ptr, "record_from_union")
  builder.extract_value(record_struct, field_index, "#{@property}_value")
end
```

### Ruby-Side Type Dispatch (Mixed Unions)

```ruby
# In lib/stone/ast/program_unit.rb

class MixedUnionValueConverter
  def convert
    return nil if null_value?
    return convert_int_or_string if has?("Int") && has?("String")
    convert_single_type
  end

  private def convert_int_or_string
    # Use type tag to determine actual type, then interpret payload
    case actual_type_name
    when "Int" then @payload  # Already i64
    when "String" then read_string_from_pointer
    end
  end
end
```

## Test Cases (All Passing)

```ruby
describe "variable-sized union payloads" do
  it "handles Int | Null (8 byte payload)" do
    code = <<~STONE
      Box := Record(value :: Int | Null)
      b := Box(42)
      b.value
    STONE
    expect(Stone.eval(code)).to eq(42)
  end

  it "handles String | Null without ptr2int" do
    code = <<~STONE
      MaybeString := Record(value :: String | Null)
      s := MaybeString("hello")
      s.value
    STONE
    expect(Stone.eval(code)).to eq("hello")
  end

  it "handles Record | Null without ptr2int" do
    code = <<~STONE
      Inner := Record(x :: Int)
      Outer := Record(value :: Inner | Null)
      o := Outer(Inner(42))
      o.value.x
    STONE
    expect(Stone.eval(code)).to eq(42)
  end

  it "handles Int | String (mixed-type union)" do
    code = <<~STONE
      Box := Record(value :: Int | String)
      b := Box("hello")
      b.value
    STONE
    expect(Stone.eval(code)).to eq("hello")
  end

  it "handles chained access through union fields" do
    code = <<~STONE
      Point := Record(x :: Int, y :: Int)
      Box := Record(point :: Point | Null)
      b := Box(Point(10, 20))
      b.point.x
    STONE
    expect(Stone.eval(code)).to eq(10)
  end

  it "handles recursive types with NULL terminator" do
    code = <<~STONE
      IntList := Record(first :: Int, rest :: IntList | Null)
      list := IntList(1, IntList(2, NULL))
      list.rest.first
    STONE
    expect(Stone.eval(code)).to eq(2)
  end
end
```

## Files Modified

1. `lib/stone/type.rb` - Added `size_bytes`, `payload_size`, `homogeneous?`,
   `common_llvm_result_type`, `property_return_type` for Union class
2. `lib/stone/ast/record_instantiation.rb` - CHERI-safe payload storage
3. `lib/stone/ast/property_access.rb` - Homogeneous/mixed extraction,
   chained property access on union fields
4. `lib/stone/ast/program_unit.rb` - `MixedUnionValueConverter` for Ruby-side dispatch
5. `spec/language/types/union_type_spec.rb` - Comprehensive test coverage

## Remaining Work

1. **i128 support** - Requires adding Int128 type to Stone (future work)
2. **Bool | Int extraction** - Needs runtime type dispatch for mixed primitive
   unions (1 pending test)

## Benefits Achieved

1. **Supports large types** - Ready for i128, f128, etc. when added
2. **CHERI-compatible** - No `ptr2int`/`int2ptr`, pointers stay as pointers
3. **More efficient** - No heap allocation for inline values
4. **Rust-like semantics** - Familiar to systems programmers
5. **Future-proof** - Works with any pointer size
