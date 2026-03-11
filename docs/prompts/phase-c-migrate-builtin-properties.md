# Phase C: Migrate Built-in Properties to Computed Properties

## Overview

Migrate the existing built-in properties (`Bool.not`, `Int.positive?`, `Int.negative?`, `Int.zero?`) from the `PropertyRegistry` implementation to the new computed property system. This validates that the computed property system can handle all the use cases that built-ins support.

## Prerequisites

- Phase A (Static Type System) must be completed
- Phase B (Computed Properties) must be completed

## Goals

1. Redefine `Bool.not` as `Bool@not := λ(this) { ... }`
2. Redefine `Int.positive?` as `Int@positive? := λ(this) { ... }`
3. Redefine `Int.negative?` as `Int@negative? := λ(this) { ... }`
4. Redefine `Int.zero?` as `Int@zero? := λ(this) { ... }`
5. Remove or deprecate the `PropertyRegistry` system
6. Ensure all existing tests continue to pass

## Current Built-in Implementations

From `lib/stone/properties.rb`:

```ruby
# Bool.not - bitwise NOT
register("Bool", "not") do |builder, value|
  builder.not(value)
end

# Int.positive? - signed greater than zero
register("Int", "positive?") do |builder, value|
  builder.icmp(:sgt, value, LLVM::Int64.from_i(0))
end

# Int.negative? - signed less than zero
register("Int", "negative?") do |builder, value|
  builder.icmp(:slt, value, LLVM::Int64.from_i(0))
end

# Int.zero? - equal to zero
register("Int", "zero?") do |builder, value|
  builder.icmp(:eq, value, LLVM::Int64.from_i(0))
end
```

## Stone-Native Implementations

### Bool@not

```stone
Bool@not := λ(this) {
  if(this, { FALSE }, { TRUE })
}
```

Note: This is a straightforward implementation using the existing `if` function.

### Int@positive?

```stone
Int@positive? := λ(this) {
  this > 0
}
```

Note: Uses the existing `>` comparison operator.

### Int@negative?

```stone
Int@negative? := λ(this) {
  this < 0
}
```

Note: Uses the existing `<` comparison operator.

### Int@zero?

```stone
Int@zero? := λ(this) {
  this == 0
}
```

Note: Uses the existing `==` comparison operator.

## Implementation Strategy

### Option A: Stone Prelude (Recommended)

Create a prelude file that defines the standard library properties in Stone code:

1. Create `lib/stone/prelude.stone`:

    ```stone
    # Boolean properties
    Bool@not := λ(this) { if(this, { FALSE }, { TRUE }) }

    # Integer properties
    Int@positive? := λ(this) { this > 0 }
    Int@negative? := λ(this) { this < 0 }
    Int@zero? := λ(this) { this == 0 }
    Int@abs := λ(this) { if(this.negative?, { 0 - this }, { this }) }

    # String properties
    String@empty? := λ(this) { this.byte_count == 0 }
    ```

2. Load the prelude automatically when creating a new Stone module

3. In `ProgramUnit#compile`, prepend the prelude before user code

### Option B: Ruby-defined Computed Properties

Register the computed properties from Ruby during module setup:

```ruby
# In TopFunction or ProgramUnit setup
def setup_standard_properties(mod, builder)
  # Define Bool@not
  bool_not_lambda = Stone::AST::Lambda.new(["this"], [
    # ... AST for if(this, { FALSE }, { TRUE })
  ])
  bool_not_func = bool_not_lambda.to_llir(builder, mod)
  mod.register_computed_property("Bool", "not", bool_not_func)

  # ... similar for other properties
end
```

This is more complex but doesn't require a prelude parser step.

### Option C: Hybrid Approach

Keep the Ruby `PropertyRegistry` as a fallback for performance-critical built-ins, but also support Stone-defined computed properties with the same lookup precedence as built-ins.

This is the safest migration path but adds complexity.

## Recommended Approach: Option A (Prelude)

### Step 1: Create Prelude File

Create `lib/stone/prelude.stone` with the property definitions.

### Step 2: Modify ProgramUnit to Load Prelude

Update `lib/stone/ast/program_unit.rb`:

```ruby
def compile
  parse_tree = parse(input_with_prelude)
  transform(parse_tree)
end

private def input_with_prelude
  "#{prelude_code}\n#{@input}"
end

private def prelude_code
  @prelude_code ||= File.read(prelude_path)
end

private def prelude_path
  File.expand_path("../prelude.stone", __dir__)
end
```

### Step 3: Update PropertyAccess Priority

Update `PropertyAccess#to_llir` to check computed properties BEFORE built-ins (or remove built-in check entirely):

```ruby
def to_llir(builder, mod)
  return access_record_field(builder, mod) if record_field_access?(mod)
  return access_constant(builder, mod) if constant_access?(mod)

  receiver_type = infer_type(@receiver, mod)

  # Computed properties first (includes prelude-defined ones)
  return access_computed_property(builder, mod, receiver_type) if computed_property?(mod, receiver_type)

  # Fall back to built-in properties (can be removed once migration complete)
  return access_builtin_property(builder, mod, receiver_type) if builtin_property?(receiver_type)

  fail Stone::PropertyError, "Property '#{@property}' not found for type '#{receiver_type}'"
end
```

### Step 4: Remove PropertyRegistry (After Verification)

Once all tests pass:

1. Remove `lib/stone/properties.rb`
2. Remove the `require` from wherever it's loaded
3. Remove the `builtin_property?` and `access_builtin_property` methods from PropertyAccess
4. Update any documentation

## Verification Steps

1. Run existing property tests to ensure they still pass:

   ```bash
   bundle exec rspec spec/language/properties/
   ```

2. Verify each property individually:

   ```bash
   bundle exec rspec spec/language/properties/bool_properties_spec.rb
   bundle exec rspec spec/language/properties/int_properties_spec.rb
   bundle exec rspec spec/language/properties/string_properties_spec.rb
   ```

3. Run the full test suite:

   ```bash
   make test
   ```

## Test Cases

No new tests are needed - the existing tests in `spec/language/properties/` should continue to pass. The migration is successful if:

- `TRUE.not` returns `FALSE`
- `FALSE.not` returns `TRUE`
- `42.positive?` returns `TRUE`
- `(-5).positive?` returns `FALSE`
- `0.positive?` returns `FALSE`
- `(-5).negative?` returns `TRUE`
- `42.negative?` returns `FALSE`
- `0.negative?` returns `FALSE`
- `0.zero?` returns `TRUE`
- `42.zero?` returns `FALSE`
- Property chaining works: `0.zero?.not` returns `FALSE`

## Files to Create

1. `lib/stone/prelude.stone` - Standard library definitions in Stone

## Files to Modify

1. `lib/stone/ast/program_unit.rb` - Load prelude before user code
2. `lib/stone/ast/property_access.rb` - Adjust priority (computed before built-in)

## Files to Remove (After Verification)

1. `lib/stone/properties.rb` - PropertyRegistry no longer needed

## Acceptance Criteria

- [ ] All properties defined in Stone code (prelude.stone)
- [ ] Prelude loaded automatically for every compilation
- [ ] All existing property tests pass
- [ ] Property chaining still works
- [ ] PropertyRegistry removed (or deprecated)
- [ ] `make test` passes
- [ ] `make lint` passes

## Potential Issues

### 1. String.byte_count Special Case

`String.byte_count` is currently handled specially in `PropertyAccess#to_llir` because it needs access to the AST node for compile-time evaluation of string literals:

```ruby
if @property == "byte_count"
  string_literal = get_string_literal(mod)
  return LLVM::Int64.from_i(string_literal.bytesize) if string_literal
end
```

This cannot be easily migrated to a computed property because computed properties only have access to the runtime value, not the AST. For now, keep `String.byte_count` as a special case.

### 2. Performance

Computed properties involve a function call, whereas built-ins generate inline LLVM instructions. This may have a slight performance impact. For Phase 1, this is acceptable. Future optimization could inline simple computed properties.

### 3. Circular Dependencies

The prelude defines properties using existing features like `if`, `>`, `<`, `==`. These must be available before the prelude runs. Since they're built-in functions (not properties), this should work fine.

### 4. Error Messages

If there's an error in the prelude, it will be confusing because users didn't write that code. Consider:

- Clear file/line information in errors
- Wrapping prelude loading in a try/catch with helpful error messages
- Testing the prelude thoroughly

## Notes

- The prelude approach mirrors how many languages work (Haskell's Prelude, Rust's std prelude, etc.)
- Future prelude additions: `Int@abs`, `String@empty?`, `String@length`, etc.
- Consider making the prelude optional or customizable in the future
- The prelude should be considered "frozen" - it's part of the language, not user code

## Commit Strategy

This migration should be done in careful steps:

1. **First commit**: Add prelude infrastructure (prelude.stone, loading mechanism)
2. **Second commit**: Verify all tests pass with prelude loaded (properties defined twice: prelude + PropertyRegistry)
3. **Third commit**: Update PropertyAccess to prefer computed properties
4. **Fourth commit**: Remove PropertyRegistry, verify tests still pass
