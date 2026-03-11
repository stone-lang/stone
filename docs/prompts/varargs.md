# Varargs (Variable Arguments)

## Overview

Implement variable-length argument lists (varargs) in Stone.
A vararg parameter collects zero or more trailing arguments into a `List` at the call site.
This enables functions like `sum(1, 2, 3, 4, 5)` and flexible APIs with optional trailing arguments.

## Prerequisites

- **List type** - Varargs are collected into a `List(T)`
- **Generic types** - For `List(T)` type
- **Type annotation scoping** - For resolving types in parameter annotations

## Goals

1. Parse vararg parameter syntax: `λ(x, y...)`
2. Only allow vararg parameter as the last parameter
3. Support empty varargs (zero trailing arguments)
4. Homogeneous varargs only (all elements same type)
5. At call sites, compiler constructs a `List` from the vararg arguments
6. Inside the function, the vararg parameter has type `List(T)`

## Syntax

### Basic (untyped) varargs

```stone
my_func := λ(x, y...) { y.map(λ(z) { z + x }) }

# Called as:
my_func(10, 1, 2, 3)
# x = 10
# y = List(Int)(1, List(Int)(2, List(Int)(3, NULL)))
```

### Typed varargs

```stone
sum := λ(numbers...: List(Int)) {
    List@fold(numbers, 0, λ(acc, n) { acc + n })
}

# Called as:
sum(1, 2, 3, 4, 5)  # Returns 15
sum()               # Returns 0 (empty list)
```

### Mixed regular and vararg parameters

```stone
format := λ(template: String, values...: List(String)) {
    # template = "Hello, {} and {}!"
    # values = List of strings to substitute
}

format("Hello, {} and {}!", "Alice", "Bob")
```

## Design Decisions

### Decision 1: Vararg Position

Only the final parameter can be a vararg.
This avoids ambiguity in parsing call sites:

```stone
# Valid:
λ(x, y, z...)
λ(a...)

# Invalid:
λ(x..., y)     # Error: vararg must be last
λ(x..., y...)  # Error: only one vararg allowed
```

### Decision 2: Type Annotation Syntax

Syntax: `param...: List(T)`

The type annotation follows the `...`, and must be a `List` type:

```stone
λ(nums...: List(Int))
λ(items...: List(String))
λ(mixed...)  # Untyped - inferred or error
```

Rationale: The `...` modifies the parameter, so it stays with the name. The type (`List(Int)`) describes what the parameter *is*, which is a List.

HELP: How do other typed languages with varargs handle this?
Do they generally explicitly include the `List()` part in the parameter type?

### Decision 3: Empty Varargs

Calling a function with zero vararg arguments is valid:

```stone
sum := λ(numbers...: List(Int)) { ... }
sum()  # numbers == empty list, so the implementation should handle that
```

### Decision 4: Spread Operator

**Terminology**: Stone calls this "spread" (following JavaScript/TypeScript conventions). Ruby calls the equivalent feature "splat". Both use `...` or `*` syntax in various languages.

Users can pass an existing list to a vararg position using the spread operator:

```stone
items := List(Int)(1, List(Int)(2, NULL))
sum(...items)  # Equivalent to sum(1, 2)
```

The spread operator "unpacks" a list into individual arguments at the call site.

#### Spread Semantics

1. **Basic spread**: `f(...list)` unpacks list elements as arguments
2. **Spread with other args**: `f(a, b, ...list)` - spread after regular args
3. **Spread to vararg**: `f(x, ...rest)` where `rest` fills the vararg parameter
4. **Type checking**: Spread list element type must match expected parameter types

#### Spread Syntax

```stone
# Spreading into a vararg parameter
nums := List(Int)(1, List(Int)(2, List(Int)(3, NULL)))
sum(...nums)  # Calls sum(1, 2, 3)

# Spreading with leading regular arguments
base := 10
sum(base, ...nums)  # If sum is λ(init, nums...) - init=10, nums=[1,2,3]
```

**Implementation note**: It may make sense to implement spread in a separate commit after the main varargs work is complete and tested.

### Decision 5: Homogeneous Types Only

All vararg values must be the same type:

```stone
# Valid:
sum(1, 2, 3)  # All Int

# Invalid (if type checking enabled):
mixed(1, "two", 3)  # Mixed types - type error
```

## Current State

Stone currently has:

- Lambda parameters as simple identifiers: `λ(x, y) { ... }`
- Type declarations: `x :: Int`
- Grammar rule: `rule(:parameter) { identifier }`
- No parameter-level type annotations in lambdas
- List type

## Desired State

### Grammar

The grammar should support 4 parameter forms:

1. Simple: `x`
2. Typed: `x: Int`
3. Untyped vararg: `x...`
4. Typed vararg: `x...: List(Int)`

### AST

Parameters should carry:

- Name (string)
- Type annotation (optional)
- Vararg flag (boolean)

### Code Generation

**At function definition:**

- Vararg parameter becomes a regular parameter of type List
- Function signature includes the List type for the vararg

**At call site:**

- Compiler determines which arguments go to regular params vs vararg
- Vararg arguments are assembled into a List (right-to-left cons)
- The List is passed as the final argument

## Test Cases

### Grammar Tests

```ruby
RSpec.describe "Vararg Parameter Parsing" do
  it "parses simple vararg parameter" do
    code = "λ(x...) { x }"
    expect { Stone.parse(code) }.not_to raise_error
  end

  it "parses typed vararg parameter" do
    code = "λ(nums...: List(Int)) { nums }"
    expect { Stone.parse(code) }.not_to raise_error
  end

  it "parses mixed parameters with vararg last" do
    code = "λ(x: Int, y: String, rest...: List(Int)) { rest }"
    expect { Stone.parse(code) }.not_to raise_error
  end

  it "parses spread argument" do
    # Note: Ruby calls this "splat"; Stone uses "spread" (JS/TS convention)
    code = "s := List(String)(\"first\", List(String)(\"second\", NULL))
            f := λ(x: Int, rest...: List(String)) { rest }
            f(1, ...s)"
    expect { Stone.parse(code) }.not_to raise_error
  end
end
```

### Validation Tests

```ruby
RSpec.describe "Vararg Validation" do
  it "rejects vararg not in last position" do
    code = "λ(x..., y) { x }"
    expect { Stone.eval(code) }.to raise_error(/vararg.*last/i)
  end

  it "rejects multiple varargs" do
    code = "λ(x..., y...) { x }"
    expect { Stone.eval(code) }.to raise_error(/one vararg/i)
  end
end
```

### Basic Vararg Functionality

```ruby
RSpec.describe "Varargs" do
  before do
    # Assume List is define List as: Record(first :: Int, rest :: List)
  end

  it "collects trailing arguments into a list" do
    code = <<~STONE
      count := λ(items...: List) {
        if(items == NULL, { 0 }, { 1 + count(items.rest) })
      }
      count(1, 2, 3, 4, 5)
    STONE
    expect(Stone.eval(code)).to eq(5)
  end

  it "handles empty varargs" do
    code = <<~STONE
      count := λ(items...: List) {
        if(items == NULL, { 0 }, { 1 + count(items.rest) })
      }
      count()
    STONE
    expect(Stone.eval(code)).to eq(0)
  end

  it "handles single vararg argument" do
    code = <<~STONE
      first_or_zero := λ(items...: List) {
        if(items == NULL, { 0 }, { items.first })
      }
      first_or_zero(42)
    STONE
    expect(Stone.eval(code)).to eq(42)
  end
end
```

### Mixed Parameters

```ruby
RSpec.describe "Varargs with regular parameters" do
  it "separates regular args from varargs" do
    code = <<~STONE
      add_to_first := λ(base: Int, nums...: List) {
        if(nums == NULL, { base }, { nums.first + base })
      }
      add_to_first(10, 1, 2, 3)
    STONE
    expect(Stone.eval(code)).to eq(11)  # 10 + 1
  end

  it "handles multiple regular params before vararg" do
    code = <<~STONE
      combine := λ(a: Int, b: Int, rest...: List) {
        if(rest == NULL, { a + b }, { a + b + rest.first })
      }
      combine(1, 2, 3, 4, 5)
    STONE
    expect(Stone.eval(code)).to eq(6)  # 1 + 2 + 3
  end

  it "works with zero vararg arguments" do
    code = <<~STONE
      combine := λ(a: Int, b: Int, rest...: List) {
        if(rest == NULL, { a + b }, { a + b + rest.first })
      }
      combine(1, 2)
    STONE
    expect(Stone.eval(code)).to eq(3)  # 1 + 2, empty rest
  end
end
```

### Integration with List Operations

```ruby
RSpec.describe "Varargs with List operations" do
  it "can use fold on vararg list" do
    code = <<~STONE
      List@fold := λ(this, init, f) {
        if(this == NULL, { init }, { List@fold(this.rest, f(init, this.first), f) })
      }

      sum := λ(nums...: List) {
        List@fold(nums, 0, λ(acc, n) { acc + n })
      }

      sum(1, 2, 3, 4, 5)
    STONE
    expect(Stone.eval(code)).to eq(15)
  end
end
```

### Spread Operator

Note: Ruby calls this feature "splat". Stone uses "spread" following JavaScript/TypeScript conventions.

```ruby
RSpec.describe "Spread operator" do
  # Helper to define sum function with varargs
  let(:sum_def) do
    <<~STONE
      List@fold := λ(this, init, f) {
        if(this == NULL, { init }, { List@fold(this.rest, f(init, this.first), f) })
      }

      sum := λ(nums...: List(Int)) {
        List@fold(nums, 0, λ(acc, n) { acc + n })
      }
    STONE
  end

  describe "parsing" do
    it "parses spread argument syntax" do
      code = <<~STONE
        items := List(Int)(1, List(Int)(2, NULL))
        f := λ(x...: List(Int)) { x }
        f(...items)
      STONE
      expect { Stone.parse(code) }.not_to raise_error
    end

    it "parses spread after regular arguments" do
      code = <<~STONE
        items := List(Int)(1, NULL)
        f := λ(a: Int, rest...: List(Int)) { a }
        f(10, ...items)
      STONE
      expect { Stone.parse(code) }.not_to raise_error
    end
  end

  describe "basic spread" do
    it "spreads a list into vararg parameter" do
      code = <<~STONE
        #{sum_def}
        nums := List(Int)(1, List(Int)(2, List(Int)(3, NULL)))
        sum(...nums)
      STONE
      expect(Stone.eval(code)).to eq(6)
    end

    it "spreads an empty list" do
      code = <<~STONE
        #{sum_def}
        empty := NULL
        sum(...empty)
      STONE
      expect(Stone.eval(code)).to eq(0)
    end

    it "spreads a single-element list" do
      code = <<~STONE
        #{sum_def}
        single := List(Int)(42, NULL)
        sum(...single)
      STONE
      expect(Stone.eval(code)).to eq(42)
    end
  end

  describe "spread with regular arguments" do
    it "spreads list after regular arguments" do
      code = <<~STONE
        add_to_all := λ(base: Int, nums...: List(Int)) {
          List@fold := λ(this, init, f) {
            if(this == NULL, { init }, { List@fold(this.rest, f(init, this.first), f) })
          }
          List@fold(nums, base, λ(acc, n) { acc + n })
        }

        extras := List(Int)(1, List(Int)(2, List(Int)(3, NULL)))
        add_to_all(100, ...extras)
      STONE
      expect(Stone.eval(code)).to eq(106)  # 100 + 1 + 2 + 3
    end

    it "spreads empty list after regular arguments" do
      code = <<~STONE
        first_or_default := λ(default: Int, nums...: List(Int)) {
          if(nums == NULL, { default }, { nums.first })
        }

        empty := NULL
        first_or_default(42, ...empty)
      STONE
      expect(Stone.eval(code)).to eq(42)
    end
  end

  describe "spread with mixed literal and spread arguments" do
    it "combines literal args and spread" do
      code = <<~STONE
        #{sum_def}
        more := List(Int)(3, List(Int)(4, NULL))
        sum(1, 2, ...more)
      STONE
      expect(Stone.eval(code)).to eq(10)  # 1 + 2 + 3 + 4
    end
  end

  describe "spread validation" do
    it "rejects spread of non-list value" do
      code = <<~STONE
        f := λ(x...: List(Int)) { x }
        f(...42)
      STONE
      expect { Stone.eval(code) }.to raise_error(/spread.*list/i)
    end
  end

  describe "spread type checking" do
    it "accepts spread when list element type matches vararg type" do
      code = <<~STONE
        int_sum := λ(nums...: List(Int)) {
          if(nums == NULL, { 0 }, { nums.first + int_sum(...nums.rest) })
        }
        ints := List(Int)(1, List(Int)(2, NULL))
        int_sum(...ints)
      STONE
      expect(Stone.eval(code)).to eq(3)
    end

    # Type mismatch test - when type checking is enabled
    it "rejects spread when list element type mismatches" do
      code = <<~STONE
        int_sum := λ(nums...: List(Int)) { 0 }
        strings := List(String)("a", List(String)("b", NULL))
        int_sum(...strings)
      STONE
      expect { Stone.eval(code) }.to raise_error(/type/i)
    end
  end
end
```

## Files to Create

1. `lib/stone/ast/parameter.rb` - Parameter AST node with name, type, and vararg flag
2. `spec/unit/parser/vararg_parsing_spec.rb` - Grammar/parsing tests
3. `spec/language/varargs_spec.rb` - Integration tests

## Files to Modify

1. `lib/stone/grammar.rb` - Add vararg parameter syntax
2. `lib/stone/transform.rb` - Transform vararg parameters to AST nodes
3. `lib/stone/ast/lambda.rb` - Validate vararg position, handle vararg in code gen
4. `lib/stone/ast/function_call.rb` - Build List for vararg arguments at call site
5. `lib/extensions/llvm_module.rb` - Track function metadata including vararg info

## Acceptance Criteria

### Vararg Parameters

- [ ] `λ(x...)` parses correctly
- [ ] `λ(x...: List(Int))` parses correctly
- [ ] `λ(a, b, c...)` parses - vararg is last
- [ ] `λ(a..., b)` raises syntax error - vararg must be last
- [ ] `λ(a..., b...)` raises syntax error - only one allowed
- [ ] `f(1, 2, 3)` where f has `(x, y...)` passes `x=1`, `y=List(2, 3)`
- [ ] `f(1)` where f has `(x, y...)` passes `x=1`, `y=NULL`
- [ ] Vararg parameter has List type inside function body

### Spread Operator

- [ ] `f(...list)` parses correctly
- [ ] `f(a, b, ...list)` parses correctly - spread after regular args
- [ ] `f(...list)` unpacks list elements as individual arguments
- [ ] `f(...empty)` where empty is NULL passes empty list to vararg
- [ ] `f(1, 2, ...list)` combines literal args and spread
- [ ] `f(...non_list)` raises error - spread requires a list
- [ ] Spread type checking: list element type must match parameter type

### General

- [ ] All existing tests pass
- [ ] `make test` passes
- [ ] `make lint` passes

## Gotchas and Challenges

### 1. List Type Dependency

Varargs require a working List type. If List isn't implemented yet, varargs will need to wait or use a simple hardcoded list structure.

### 2. Call Site Argument Count

The compiler needs to know a function's signature to correctly split arguments:

```stone
f := λ(x, y...) { ... }
f()     # Error: missing required argument x
f(1)    # Valid: x=1, y=empty
f(1, 2, 3)  # Valid: x=1, y=[2,3]
```

### 3. Function Signature Lookup

At call sites, the compiler must look up the callee's signature to know if/where the vararg is. This may require two-pass compilation or forward declaration tracking.

### 4. Stack vs Heap for List Nodes

The List nodes created at call sites need memory. Stack allocation is simple but may have lifetime issues if the list escapes. Start with stack; revisit if needed.

### 5. Type Inference for Untyped Varargs

If no type annotation is provided (`λ(x...)`), options include:

- Require annotations (strict)
- Infer from usage (complex)
- Default to untyped/dynamic

Start with required annotations for simplicity.

## Future Enhancements

### Heterogeneous Varargs

```stone
log := λ(items...: List(Int | String)) { ... }
log(1, "hello", 2)
```

## Relationship to Other Features

### Prerequisites

- **List type**: Varargs ARE Lists
- **Generic types**: For `List(T)` parameterization
- **Type annotations on parameters**: For `param: Type` syntax

### Enables

- Variadic functions: `print`, `sum`, `concat`, `format`
- Flexible builder patterns
- Printf-style APIs

### Related

- Pattern matching (destructuring varargs)
- Default parameter values

## Notes

- The `...` syntax follows JavaScript/TypeScript/Kotlin conventions
- List representation: `Record(first :: T, rest :: List(T))` with NULL as empty
- Vararg construction happens at call site - function just sees a List parameter
- Start with required type annotations; relax later if desired

## Wrap-Up

Once you've completed the implementation:

- Update this file with any as-built changes we made to the design
    - Don't overwrite original design decisions
- Include this updated file as part of the commit
- Add any lessons learned to your "memory"
- Run the `/retro` command
