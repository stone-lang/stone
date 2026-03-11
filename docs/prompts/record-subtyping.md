# Record Subtyping (Nominal Inheritance)

## Overview

Implement nominal subtyping for Record types, allowing a record to inherit
fields and computed properties from a base record type. Subtypes are defined
with `.subclass()` syntax:

```stone
Animal := Record(name :: String)
Dog := Animal.subclass(breed :: String)
```

`Dog` has both `name` (inherited) and `breed` (added) fields.
Computed properties defined on `Animal` are also available on `Dog`.

## Related Features

### Prerequisites

- Record types (done)
- Computed properties / `Type@property` pattern (done)
- RTTI infrastructure (done)
- Union types with runtime type dispatch (done)

### Enables

- Type hierarchies and code reuse
- `is?()` type checking across inheritance chains
- Foundation for polymorphic dispatch (Phase 2)
- Algebraic data type patterns with inheritance

## Goals

1. Define subtypes: `Dog := Animal.subclass(breed :: String)`
2. Subtypes inherit all fields from the base type
3. Subtypes inherit all computed properties from the base type
4. `is?(value, Type)` built-in function for type checking
5. Track parent type in `Type` for superclass chain walking

## Non-Goals

- Multiple inheritance
- Interfaces / protocols / traits
- Method overriding (Phase 2)
- Assignment compatibility: passing a `Dog` where `Animal` is expected (Phase 2)
- Runtime polymorphic dispatch / vtables (Phase 2)
- `x.is?(T)` method-call syntax (Phase 2 - needs method-with-arguments support)

## Problem Statement

Currently, record types are standalone. Two records with overlapping fields
must each declare all fields independently, and computed properties defined
on one type cannot be reused by another:

```stone
Animal := Record(name :: String)
Dog := Record(name :: String, breed :: String)  # Duplicates `name`

Animal@speak := λ(this) { this.name }
# Dog doesn't get `speak` - must redefine it manually
```

There is also no way to ask whether a value is of a given type or a subtype.

## Design Decisions

### 1. Struct Layout

Subclass structs start with all base fields in the same order,
followed by additional fields:

```text
Animal struct: { name :: String }           → LLVM: { ptr }
Dog struct:    { name :: String, breed :: String } → LLVM: { ptr, ptr }
```

This ensures the first N fields of a subclass struct are layout-compatible
with the base struct, which simplifies field extraction when calling
inherited methods.

### 2. Method Inheritance: Hybrid (Auto-Copy + Chain Lookup)

A hybrid approach combines the benefits of both strategies:

**At subclass definition time** (in `top_function.rb`): scan
`mod.function_aliases` for all `ParentType@*` entries. For each,
register `SubType@*` pointing to the **same LLVM function**. This
is a simple alias copy — no wrapper functions.

**At call site** (in `PropertyAccess`): when calling a computed
property, compare the found function's first parameter type with
the receiver's LLVM type. If they differ (inherited method), extract
the base fields from the subclass struct before calling:

```text
dog.speak
  → lookup Dog@speak (found via auto-copy alias)
  → func expects Animal struct, receiver is Dog struct
  → extract base fields: {name} from {name, breed}
  → call Animal@speak({name})
```

**Fallback chain lookup**: if `SubType@method` is not in aliases
(because the base method was defined AFTER the subclass), walk the
parent chain at compile time:

```stone
Animal := Record(name :: String)
Dog := Animal.subclass(breed :: String)
Animal@speak := λ(this) { this.name }  # Defined after Dog
d := Dog("Rex", "Lab")
d.speak  # Not in Dog aliases → walk chain → find Animal@speak
```

The base-field extraction logic in PropertyAccess is the same in
both cases — it just checks whether the function's parameter type
matches the receiver type. No wrapper functions are generated.

All resolution happens at **compile time** (Phase 1 has no assignment
compatibility, so the static type always equals the runtime type).

### 3. `is?()` Type Checking

#### Phase 1: Built-in function with compile-time resolution

```stone
is?(dog, Dog)     # => TRUE (exact match)
is?(dog, Animal)  # => TRUE (Dog is subtype of Animal)
is?(dog, String)  # => FALSE (unrelated types)
is?(42, Int)      # => TRUE
```

Implemented as a special-cased built-in function that the compiler
resolves statically. Since Phase 1 has no assignment compatibility,
the static type is always the runtime type, so compile-time resolution
is sufficient.

#### Why a function instead of a property?

The natural syntax would be `dog.is?(Animal)`, but Stone's computed
properties don't take arguments (only implicit `this`). Making `is?`
a two-argument function `is?(value, Type)` works with existing
infrastructure. The method-call syntax `x.is?(T)` can be added in
Phase 2 when Stone supports methods with explicit arguments.

#### Semantics (`instanceof`)

`is?(x, T)` returns `TRUE` if the type of `x` is `T` or any subtype
of `T`. In other words, `is?` walks UP the superclass chain from x's
type, checking for a match with T:

- `is?(dog, Dog)` → TRUE (exact match)
- `is?(dog, Animal)` → TRUE (Dog's parent is Animal)
- `is?(animal, Dog)` → FALSE (Animal is not a subtype of Dog)

This matches Ruby's `is_a?` / Java's `instanceof` semantics.

The second argument is a **type reference** (like `Dog`, `Animal`,
`Int`), not a value expression. This is the same pattern used by
`Type.of()` where the argument has special compile-time meaning.

### 4. Type Compatibility / Assignment (Phase 2)

Phase 1 does NOT support assigning a subtype value to a supertype
variable. Each variable holds exactly the type it was declared as:

```stone
# Phase 1: NOT supported
a :: Animal = Dog("Rex", "Lab")  # Error or not yet implemented
```

Phase 2 can leverage Stone's existing union + type dispatch
infrastructure. A supertype variable holding a subtype value would
use the same tagged-union representation that unions already use.
The user's insight about desugaring `s.method()` to
`ActualType@method(s)` at runtime aligns with this approach -
the type tag determines which `Type@method` to call, exactly as
union type dispatch already works.

### 5. `.subclass()` as a Special-Cased Form (like `Type.of()`)

`.subclass()` **must** be a grammar-level special case because its
arguments are **type declarations** (`breed :: String`), not
expressions. The argument list parser expects expressions, so
`Animal.subclass(breed :: String)` would fail to parse as a normal
postfix expression. This is the same reason `Record(...)` has its own
grammar rule.

Following the `Type.of()` pattern, the special-casing happens at
three levels:

#### Grammar

```ruby
rule(:subclass_definition) {
  identifier + str(".subclass") + parens(comma_separated(type_declaration, allow_trailing: false))
}
```

Added to the `primary` rule alongside `record_definition` and
`type_of_expression`.

#### Transform

Creates a `SubclassDefinition` AST node that stores the parent type
name and only the additional fields:

```ruby
transform(:subclass_definition) do |node|
  parent_name = extract_identifier(node)
  additional_fields = extract_type_declarations(node)
  Stone::AST::SubclassDefinition.new(parent_name, additional_fields)
end
```

#### AST node

`SubclassDefinition` is a thin node storing `parent_name` and
`additional_fields`. It does NOT inherit from `RecordDefinition`.
During type registration (in `top_function.rb`), it resolves into
a full `RecordDefinition` with merged fields — at that point the
parent type's fields are available from the module's record type
registry. The rest of the system only sees `RecordDefinition`.

```ruby
class SubclassDefinition < Stone::AST
  attr_reader :parent_name, :additional_fields
  attr_accessor :assigned_name

  def initialize(parent_name, additional_fields)
    @parent_name = parent_name
    @additional_fields = additional_fields
  end
end
```

#### Registration (in `top_function.rb`)

During `register_record_types`, detect `SubclassDefinition` and:

1. Look up the parent's `RecordDefinition` from `mod.record_types`
2. Merge fields: `parent_def.fields + subclass_def.additional_fields`
3. Create a new `RecordDefinition` with all merged fields
4. Set `assigned_name` on it
5. Register it normally (same as any record type)
6. Register the `Type` with `parent:` set to the parent's Type
7. Auto-copy existing `ParentType@*` aliases as `SubType@*`

## Implementation Steps

### Step 1: Add `parent` to Type

Track the parent type in `Stone::Type`:

```ruby
# In lib/stone/type.rb
attr_reader :parent

def self.record(name:, fields:, llvm_type:, parent: nil)
  new(name:, llvm_type:, fields:, primitive: false, parent:)
end

def subtype_of?(other)
  return true if self == other
  return false unless @parent

  @parent.subtype_of?(other)
end
```

### Step 2: Add grammar rule for `.subclass()`

Add `subclass_definition` to the grammar and include it in `primary`:

```ruby
rule(:subclass_definition) {
  identifier + str(".subclass") + parens(comma_separated(type_declaration, allow_trailing: false))
}

rule(:primary) {
  parens(expression) | type_of_expression | subclass_definition | record_definition |
    literal | type_reference | reference | lambda | block
}
```

Note: `subclass_definition` must appear before `reference` in the
`primary` alternatives so the grammar matches it before treating the
identifier as a plain reference.

### Step 3: Add `SubclassDefinition` AST node

Create `lib/stone/ast/subclass_definition.rb`:

```ruby
class SubclassDefinition < Stone::AST
  attr_reader :parent_name, :additional_fields
  attr_accessor :assigned_name

  def initialize(parent_name, additional_fields)
    @name = :subclass_definition
    @parent_name = parent_name
    @additional_fields = additional_fields
  end
end
```

This is a thin data node — it does NOT generate LLVM IR itself.
It gets resolved into a `RecordDefinition` during type registration.

### Step 4: Add transform for subclass definitions

```ruby
transform(:subclass_definition) do |node|
  parent_identifier = # extract the identifier before ".subclass"
  type_declarations = # extract type_declaration children
  fields = type_declarations.map { |td| extract_field_info(td) }
  Stone::AST::SubclassDefinition.new(parent_identifier, fields)
end
```

### Step 5: Resolve and register subclass types

In `top_function.rb`, during `register_record_types`:

```ruby
private def register_subclass_type_definition(child, mod, scope)
  return unless child.value_expression.is_a?(Stone::AST::SubclassDefinition)

  subclass_def = child.value_expression
  parent_def = mod.record_types[subclass_def.parent_name]

  # Merge: base fields first, then additional fields
  all_fields = parent_def.fields + subclass_def.additional_fields

  # Create a RecordDefinition with the merged fields
  record_def = Stone::AST::RecordDefinition.new(all_fields)
  record_def.assigned_name = child.identifier

  # Register as a normal record type
  mod.register_record_type(child.identifier, record_def)

  # Register Type with parent tracking
  parent_type = Stone::Type::Registry.lookup(subclass_def.parent_name)
  type = Stone::Type.record(
    name: child.identifier,
    fields: all_fields,
    llvm_type: record_def.llvm_type(mod, scope),
    parent: parent_type
  )
  Stone::Type::Registry.register(type)

  # Auto-copy existing parent aliases
  copy_parent_method_aliases(mod, subclass_def.parent_name, child.identifier)
end

private def copy_parent_method_aliases(mod, parent_name, subclass_name)
  prefix = "#{parent_name}@"
  mod.function_aliases.each do |name, func|
    next unless name.start_with?(prefix)

    property = name.delete_prefix(prefix)
    subclass_alias = "#{subclass_name}@#{property}"
    mod.register_function_alias(subclass_alias, func) unless mod.lookup_function(subclass_alias)
  end
end
```

### Step 6: Update PropertyAccess for inherited methods

Two changes to `handle_computed_property`:

**a) Chain lookup fallback** (for methods defined after subclass):

```ruby
private def lookup_computed_property_function(mod, receiver_type)
  type = receiver_type
  while type
    func = mod.lookup_function("#{type.name}@#{@property}")
    return [func, type] if func
    type = type.parent
  end
  nil
end
```

Returns both the function AND the type it was defined on, so we
know whether struct conversion is needed.

**b) Base-field extraction** when the function's parameter type
differs from the receiver type:

```ruby
private def call_computed_property(builder, func, defined_on_type, receiver_value, receiver_type)
  value = if defined_on_type == receiver_type
            receiver_value
          else
            extract_base_struct(builder, receiver_value, defined_on_type)
          end
  builder.call(func, value, "#{@property}_result")
end

private def extract_base_struct(builder, subclass_value, base_type)
  base_llvm = base_type.llvm_type
  base_value = LLVM::Value.undef(base_llvm)
  base_type.fields.each_with_index do |_field, i|
    field_val = builder.extract_value(subclass_value, i, "base_field_#{i}")
    base_value = builder.insert_value(base_value, field_val, i, "build_base_#{i}")
  end
  base_value
end
```

### Step 7: Implement `is?()` built-in function

Special-case `is?` in `FunctionCall` resolution. The second argument
is a type reference (resolved to a `Stone::Type` at compile time):

```ruby
# In function_call.rb
private def handle_is_check(builder, mod, scope)
  value_expr = @arguments[0]
  type_ref = @arguments[1]  # TypeReference or Reference to a type name
  type_name = type_ref.respond_to?(:identifier) ? type_ref.identifier : type_ref.name
  value_type = value_expr.type(Stone::TypeContext.new(mod))
  check_type = Stone::Type::Registry.lookup(type_name)
  result = value_type.subtype_of?(check_type)
  result ? LLVM::TRUE : LLVM::FALSE
end
```

### Step 8: Update RTTI for parent tracking (Phase 2 prep)

Add parent type pointer to the RTTI struct so runtime type checking
is possible in Phase 2:

```ruby
# Extended type struct: { ptr name, i64 size, i8 kind, ptr fields, ptr parent }
# parent is null for base types, pointer to parent Type constant for subtypes
```

This step is optional for Phase 1 (compile-time `is?` doesn't need
RTTI). Include it if the struct change is low-cost, defer otherwise.

## Test Cases

```ruby
RSpec.describe "Record Subtyping" do
  describe "defining subtypes" do
    it "can define a subtype with additional fields" do
      code = <<~STONE
        Animal := Record(name :: String)
        Dog := Animal.subclass(breed :: String)
        Dog
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end

    it "subtype has both inherited and new fields" do
      code = <<~STONE
        Animal := Record(name :: String)
        Dog := Animal.subclass(breed :: String)
        d := Dog("Rex", "Lab")
        d.name
      STONE
      expect(Stone.eval(code)).to eq("Rex")
    end

    it "can access additional fields on subtype" do
      code = <<~STONE
        Animal := Record(name :: String)
        Dog := Animal.subclass(breed :: String)
        d := Dog("Rex", "Lab")
        d.breed
      STONE
      expect(Stone.eval(code)).to eq("Lab")
    end
  end

  describe "field inheritance" do
    it "preserves field order: base fields first" do
      code = <<~STONE
        Point := Record(x :: Int, y :: Int)
        Point3D := Point.subclass(z :: Int)
        p := Point3D(1, 2, 3)
        p.x + p.y + p.z
      STONE
      expect(Stone.eval(code)).to eq(6)
    end

    it "supports multi-level inheritance" do
      code = <<~STONE
        A := Record(x :: Int)
        B := A.subclass(y :: Int)
        C := B.subclass(z :: Int)
        c := C(1, 2, 3)
        c.x + c.y + c.z
      STONE
      expect(Stone.eval(code)).to eq(6)
    end
  end

  describe "method inheritance" do
    it "inherits computed properties from base type" do
      code = <<~STONE
        Animal := Record(name :: String)
        Dog := Animal.subclass(breed :: String)
        Animal@speak := λ(this) { this.name }
        d := Dog("Rex", "Lab")
        d.speak
      STONE
      expect(Stone.eval(code)).to eq("Rex")
    end

    it "methods defined after subclass are still inherited" do
      code = <<~STONE
        Animal := Record(name :: String)
        Dog := Animal.subclass(breed :: String)
        Animal@greet := λ(this) { this.name }
        d := Dog("Buddy", "Poodle")
        d.greet
      STONE
      expect(Stone.eval(code)).to eq("Buddy")
    end

    it "inherits through multiple levels" do
      code = <<~STONE
        A := Record(x :: Int)
        B := A.subclass(y :: Int)
        C := B.subclass(z :: Int)
        A@value := λ(this) { this.x }
        c := C(10, 20, 30)
        c.value
      STONE
      expect(Stone.eval(code)).to eq(10)
    end
  end

  describe "is?() type checking" do
    it "returns TRUE for exact type match" do
      code = <<~STONE
        Animal := Record(name :: String)
        a := Animal("Rex")
        is?(a, Animal)
      STONE
      expect(Stone.eval(code)).to be(true)
    end

    it "returns TRUE when checking against a supertype" do
      code = <<~STONE
        Animal := Record(name :: String)
        Dog := Animal.subclass(breed :: String)
        d := Dog("Rex", "Lab")
        is?(d, Animal)
      STONE
      expect(Stone.eval(code)).to be(true)
    end

    it "returns FALSE for unrelated types" do
      code = <<~STONE
        Animal := Record(name :: String)
        Dog := Animal.subclass(breed :: String)
        d := Dog("Rex", "Lab")
        is?(d, Int)
      STONE
      expect(Stone.eval(code)).to be(false)
    end

    it "returns FALSE when checking supertype against subtype" do
      code = <<~STONE
        Animal := Record(name :: String)
        Dog := Animal.subclass(breed :: String)
        a := Animal("Rex")
        is?(a, Dog)
      STONE
      expect(Stone.eval(code)).to be(false)
    end

    it "works with primitive types" do
      code = <<~STONE
        is?(42, Int)
      STONE
      expect(Stone.eval(code)).to be(true)
    end

    it "works through multiple inheritance levels" do
      code = <<~STONE
        A := Record(x :: Int)
        B := A.subclass(y :: Int)
        C := B.subclass(z :: Int)
        c := C(1, 2, 3)
        is?(c, A)
      STONE
      expect(Stone.eval(code)).to be(true)
    end
  end
end
```

## Files to Create

1. `lib/stone/ast/subclass_definition.rb` - SubclassDefinition AST node
2. `spec/language/records/record_subtyping_spec.rb` - Tests

## Files to Modify

1. `lib/stone/type.rb` - Add `parent` field, `subtype_of?` method
2. `lib/stone/grammar.rb` - Add `subclass_definition` grammar rule
3. `lib/stone/transform.rb` - Add transform for subclass definitions
4. `lib/stone/ast/program_unit/top_function.rb` - Register subclass types
    with merged fields and parent tracking
5. `lib/stone/ast/property_access.rb` - Chain lookup through parent types
    with base-struct extraction
6. `lib/stone/ast/function_call.rb` - Handle `is?()` built-in function
7. `lib/stone/rtti.rb` - Add parent pointer to type struct (optional,
    for Phase 2 preparation)

## Acceptance Criteria

- [ ] `Dog := Animal.subclass(breed :: String)` compiles
- [ ] Dog instances have both inherited and additional fields
- [ ] Field access works for both inherited and new fields
- [ ] Multi-level inheritance works (A → B → C)
- [ ] Computed properties are inherited via chain lookup
- [ ] Inherited methods work regardless of definition order
- [ ] `is?(value, Type)` returns correct results
- [ ] `is?` works across inheritance chains
- [ ] `is?` works with primitive types
- [ ] All existing tests pass
- [ ] `make test` passes
- [ ] `make lint` passes

## Relationship to Other Features

### Prerequisites

- Record types (done)
- Computed properties (done)
- RTTI infrastructure (done)

### Enables

- Type hierarchies and code reuse
- Foundation for polymorphic dispatch
- Pattern matching on type hierarchies
- Error type hierarchies

### Future Enhancements (Phase 2)

- **Assignment compatibility**: `a :: Animal = Dog("Rex", "Lab")`
    - Reuses existing union + type dispatch infrastructure
    - Supertype variables use tagged-union representation internally
    - Method dispatch uses type tag: `ActualType@method(value)`
- **Method overriding**: `Dog@speak` overrides `Animal@speak`
    - With assignment compatibility, requires runtime dispatch
    - Same mechanism as union type dispatch
- **`x.is?(T)` method syntax**: Once methods support arguments
- **Runtime `is?`**: For supertype variables holding subtype values
- **Abstract methods**: Methods declared but not defined on base type

## Notes

- Subclass struct layout compatibility (base fields first) is critical
    for the field-extraction approach in method inheritance
- The hybrid auto-copy + chain lookup approach adds no runtime cost —
    all resolution is at compile time in Phase 1 (static type = runtime type)
- Auto-copy is transitive: when B extends A and C extends B, C's
    registration copies all `B@*` aliases, which already include A's
    methods (copied when B was registered)
- Phase 2's approach of reusing union infrastructure for subtype
    assignment is a key architectural insight: no vtables needed,
    just the same tagged-union dispatch Stone already has
- The `is?()` function is compile-time only in Phase 1; it becomes
    runtime when assignment compatibility is added in Phase 2
- `.subclass()` follows the same special-casing pattern as `Type.of()`:
    grammar rule → transform → AST node → resolved during registration

## Resolved Design Questions

1. **`SubclassDefinition` is its own AST class** (not extending
    `RecordDefinition`). It's a thin data node that gets resolved
    into a `RecordDefinition` during type registration. This keeps
    both classes focused.

2. **`.subclass()` is a grammar-level special case** (like `Type.of()`
    and `Record()`). Required because its arguments are type
    declarations, not expressions — the expression argument-list
    parser can't handle `breed :: String`.

3. **Method inheritance uses a hybrid approach**: auto-copy existing
    aliases at subclass definition time, chain lookup as fallback for
    methods defined later. Base-field extraction at the call site
    handles the struct type mismatch.

4. **`is?()` is a built-in function** special-cased in `FunctionCall`.
    Second argument is a type reference. Compile-time only in Phase 1.

## Open Questions

1. **Grammar ordering**: Does `subclass_definition` need to appear
    before `reference` in `primary`, or does Grammy handle the
    ambiguity via longest-match? (The identifier prefix overlaps.)

2. **Multi-level auto-copy**: When `C := B.subclass(...)` and
    `B := A.subclass(...)`, the auto-copy for C should pick up
    both `B@*` and `A@*` aliases. Since `B@*` aliases were created
    during B's registration (copying from `A@*`), copying `B@*` into
    `C@*` transitively includes A's methods. Verify this works.

## Wrap-Up

Once you've completed the implementation:

- Update this file with any as-built changes we made to the design
- Include this updated file as part of the commit
- Add any lessons learned to your "memory"
- Run the `/retro` command
