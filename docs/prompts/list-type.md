# List Type Implementation

## Overview

Implement a fully-featured, functional List type in Stone using sum types, Records, and generic types. Lists are fundamental to functional programming and provide the foundation for collection operations like map, filter, reduce, etc.

Ask any questions up front, as much as possible. Once your questions have been answered, you may continue all the way to committing and wrap-up.

## Prerequisites

- **Sum types** (`docs/prompts/sum-types.md`) — Expression-level `|` operator
- **Generic types** (`docs/prompts/generic-types.md`) — `λ(T) { ... }` parameterized types
- **Records** — `Record(field :: Type, ...)` definitions
- **NULL literal** — `Null` type with singleton `NULL` value
- **Union type representation** (`docs/prompts/union-type-representation.md`) — Tagged union LLVM layout

## Goals

1. Define List as a recursive generic sum type: `List := λ(T) { Null | Record(first :: T, rest :: List(T)) }`
2. Implement core list operations: `empty?`, `length`, `nth`, `at`, `first`, `rest`, `last`
3. Implement `fold` (with `reduce` as a no-initial-value variant) as the core iteration primitive
4. Implement functional operations using `fold`: `map`, `filter`/`select`, `reject`, `find`, `includes?`, `any?`, `all?`, `none?`
5. Implement list-building operations: `prepend`, `append`, `concat`
6. Implement utility operations: `reversed`, `take`, `drop`, `uniq`
7. Handle empty list as `NULL` (the `Null` variant of the sum type)

## Core List Definition

```stone
# Generic List type — a sum type of Null and a Record
List :: (Type) -> Type
List := λ(T) { Null | Record(first :: T, rest :: List(T)) }

# Instantiate for specific types
IntList := List(Int)
StringList := List(String)

# Create list instances (NULL terminates the list)
numbers := IntList(1, IntList(2, IntList(3, NULL)))
names := List(String)("Alice", List(String)("Bob", NULL))

# Empty list is just NULL
empty := NULL
```

## Design Decisions (Resolved)

### Decision 1: Empty List Representation

**Chosen: Sum type with `Null` variant.**

```stone
List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
```

- Uses the existing `Null` type (with singleton `NULL` value) as the empty variant
- Uses `Record(first :: T, rest :: List(T))` as the non-empty variant
- This is a proper sum type (tagged union) — `Null` and the Record are the two alternatives
- No new `Empty` type or `Cons` constructor needed — reuse what exists
- `NULL` serves as the empty list value for all `List(T)` types

**Prerequisite**: Sum types (`docs/prompts/sum-types.md`) must be implemented first.

### Decision 2: Built-in vs Stone-Implemented Operations

**Chosen: `fold` as the only built-in; `reduce` (no initial value) as an alias-like variant; everything else in pure Stone.**

- Start with a pure Stone implementation of `fold` to prove out the API
- Later, re-implement `fold` as an LLVM built-in with a non-recursive loop (tail-call optimized) for performance and to avoid stack overflow on deep lists
- `reduce` is a variant of `fold` that uses the first element as the initial accumulator (2 args instead of 3)
- All other operations (`map`, `filter`, `find`, `length`, etc.) are implemented in pure Stone using `fold`

### Decision 3: Iteration Strategy

**Chosen: Use `fold` for everything.**

All operations that iterate over the list use `fold` as their implementation primitive. This:

- Makes `fold` the single point of optimization (optimize fold, optimize everything)
- Ensures consistent behavior and performance characteristics
- Demonstrates the power of fold as a universal list operation

### Decision 4: Method Naming Conventions

**Chosen: Ruby-like names with canonical functional aliases.**

- Use canonical functional names as primary: `fold`, `filter`, `reduce`
- Provide Ruby-style aliases: `select` for `filter`, `detect` for `find`
- Use Ruby/Stone convention of `?` suffix for boolean predicates: `empty?`, `includes?`, `any?`, `all?`
- Use Ruby convention of `!` (future) for mutating operations (not applicable yet — Stone is immutable)

## Current State

Stone currently has:

- Record types with recursive references supported
- Lambda functions with closures
- Property syntax: `MyType@property := λ(this) { ... }`
- Basic types: Int, Bool, String
- Sum types via expression-level `|` (prerequisite)
- No built-in list type
- No fold/reduce built-in

## Desired State

### Core List Type

```stone
List :: (Type) -> Type
List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
```

### Core Predicates and Accessors

```stone
List@empty? := λ(this) { this == NULL }

# first and rest are record fields, accessible directly: list.first, list.rest
# These methods add NULL safety:
List@first := λ(this) {
  if(this.empty?, { NULL }, { this.first })
}

List@rest := λ(this) {
  if(this.empty?, { NULL }, { this.rest })
}

# Aliases
List@head := List@first
List@tail := List@rest
List@car := List@first
List@cdr := List@rest
```

### Fold and Reduce

This is the most critical operation — everything else builds on it.

```stone
# Left fold: f(f(f(acc, elem1), elem2), elem3)
List@fold := λ(this, acc, func) {
  if(this.empty?,
    { acc },
    {
      newAcc := func(acc, this.first)
      List@fold(this.rest, newAcc, func)
    }
  )
}

# Reduce: fold without initial value (uses first element as accumulator)
List@reduce := λ(this, func) {
  if(this.empty?,
    { NULL },
    { List@fold(this.rest, this.first, func) }
  )
}
```

**Important**: `fold` will initially be pure Stone (recursive). A later step re-implements it as an LLVM built-in with a non-recursive loop for performance and stack safety.

### Length and Indexing

```stone
List@length := λ(this) {
  List@fold(this, 0, λ(acc, elem) { acc + 1 })
}

# Aliases
List@size := List@length
List@count := List@length

# One-indexed access (not using fold — early exit is important)
List@nth := λ(this, n) {
  if(this.empty?,
    { NULL },
    {
      if(n == 1,
        { this.first },
        { List@nth(this.rest, n - 1) }
      )
    }
  )
}

# Zero-indexed access
List@at := λ(this, index) {
  List@nth(this, index + 1)
}

List@last := λ(this) {
  List@fold(this, NULL, λ(acc, elem) { elem })
}
```

### Prepend, Append, and Concat

```stone
# Prepend: O(1) — add element to head
List@prepend := λ(this, value) {
  List(T)(value, this)
}

# Append: O(n) — add element to tail (must traverse entire list)
List@append := λ(this, value) {
  List@concat(this, List(T)(value, NULL))
}

# Concat: O(n) in first list — concatenate two lists
List@concat := λ(this, other) {
  List@fold(List@reversed(this), other, λ(acc, elem) {
    List@prepend(acc, elem)
  })
}
```

Note: `concat` reverses the first list, then prepends each element onto the second list. This preserves order and is O(n) in the length of the first list.

An alternative implementation without `reversed`:

```stone
# Alternative: build from right using explicit recursion
List@concat := λ(this, other) {
  if(this.empty?,
    { other },
    { List(T)(this.first, List@concat(this.rest, other)) }
  )
}
```

The recursive version is simpler but not tail-recursive. Since `fold` will eventually be optimized, the fold-based version is preferred.

### Map

```stone
List@map := λ(this, func) {
  reversed_result := List@fold(this, NULL, λ(acc, elem) {
    List@prepend(acc, func(elem))
  })
  List@reversed(reversed_result)
}
```

Note: `fold` naturally builds the result in reverse order (because `prepend` adds to the head). We reverse at the end to restore original order. This is O(2n) = O(n).

### Filter

```stone
List@filter := λ(this, predicate) {
  reversed_result := List@fold(this, NULL, λ(acc, elem) {
    if(predicate(elem),
      { List@prepend(acc, elem) },
      { acc }
    )
  })
  List@reversed(reversed_result)
}

List@select := List@filter

List@reject := λ(this, predicate) {
  List@filter(this, λ(x) { ¬(predicate(x)) })
}
```

### Find and Search

```stone
# Note: find uses fold but cannot short-circuit (fold always traverses the full list).
# This is O(n) even when the element is found early.
# A future optimization could add a short-circuiting fold variant.
List@find := λ(this, predicate) {
  List@fold(this, NULL, λ(acc, elem) {
    if(acc == NULL,
      { if(predicate(elem), { elem }, { NULL }) },
      { acc }
    )
  })
}

List@detect := List@find

List@includes? := λ(this, value) {
  List@fold(this, FALSE, λ(acc, elem) {
    if(acc, { TRUE }, { elem == value })
  })
}

List@any? := λ(this, predicate) {
  List@fold(this, FALSE, λ(acc, elem) {
    if(acc, { TRUE }, { predicate(elem) })
  })
}

List@some? := List@any?

List@all? := λ(this, predicate) {
  List@fold(this, TRUE, λ(acc, elem) {
    if(acc, { predicate(elem) }, { FALSE })
  })
}

List@none? := λ(this, predicate) {
  ¬(List@any?(this, predicate))
}
```

### Take and Drop

```stone
# Take cannot use fold efficiently (would need to reverse).
# Using direct recursion with early exit.
List@take := λ(this, n) {
  if(this.empty?,
    { NULL },
    {
      if(n == 0,
        { NULL },
        { List(T)(this.first, List@take(this.rest, n - 1)) }
      )
    }
  )
}

# Drop is naturally tail-recursive — a good candidate for fold-like optimization.
List@drop := λ(this, n) {
  if(this.empty?,
    { NULL },
    {
      if(n == 0,
        { this },
        { List@drop(this.rest, n - 1) }
      )
    }
  )
}
```

### Transformations

```stone
List@reversed := λ(this) {
  List@fold(this, NULL, λ(acc, elem) {
    List@prepend(acc, elem)
  })
}

List@uniq := λ(this) {
  reversed_result := List@fold(this, NULL, λ(acc, elem) {
    if(List@includes?(acc, elem),
      { acc },
      { List@prepend(acc, elem) }
    )
  })
  List@reversed(reversed_result)
}
```

### Sorted (Deferred)

Sorting requires elements to be comparable. Without type constraints, we can only offer `sorted_by` with an explicit comparator:

```stone
List@sorted_by := λ(this, compareFunc) {
  # Insertion sort or merge sort
  # Deferred until comparison infrastructure exists
}
```

If sorting is needed before type constraints, write up `docs/prompts/sorting.md`.

## Implementation Steps

### Step 0: Write tests

As always, we do TDD and write test cases before we start coding.

### Step 1: Define List Type (Sum Type)

```stone
List :: (Type) -> Type
List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
```

This requires sum types (`docs/prompts/sum-types.md`) to be implemented. The `|` operator creates a union of `Null` and the Record type.

Verify that:

- The type can be defined
- It can be instantiated: `IntList := List(Int)`
- Values can be constructed: `IntList(42, NULL)`
- `NULL` serves as the empty list

### Step 2: Implement Core Predicates and Accessors

Add to prelude:

```stone
List@empty? := λ(this) { this == NULL }

List@first := λ(this) {
  if(this.empty?, { NULL }, { this.first })
}

List@rest := λ(this) {
  if(this.empty?, { NULL }, { this.rest })
}

# Aliases
List@head := List@first
List@tail := List@rest
List@car := List@first
List@cdr := List@rest
```

Test that `empty?` works with `NULL` and non-empty lists.

### Step 3: Implement Fold and Reduce in Pure Stone

```stone
List@fold := λ(this, acc, func) {
  if(this.empty?,
    { acc },
    {
      newAcc := func(acc, this.first)
      List@fold(this.rest, newAcc, func)
    }
  )
}

List@reduce := λ(this, func) {
  if(this.empty?,
    { NULL },
    { List@fold(this.rest, this.first, func) }
  )
}
```

Test with sum, product, and string concatenation.

### Step 4: Implement Operations Using Fold

Add to prelude in dependency order (all using `fold` unless noted):

1. `length`, `size`, `count`
2. `last`
3. `prepend`
4. `reversed` (depends on `fold`, `prepend`)
5. `concat` (depends on `fold`, `reversed`, `prepend`)
6. `append` (depends on `concat`)
7. `map` (depends on `fold`, `prepend`, `reversed`)
8. `filter`, `select` (depends on `fold`, `prepend`, `reversed`)
9. `reject` (depends on `filter`)
10. `find`, `detect` (depends on `fold`)
11. `includes?` (depends on `fold`)
12. `any?`, `some?` (depends on `fold`)
13. `all?` (depends on `fold`)
14. `none?` (depends on `any?`)
15. `uniq` (depends on `fold`, `includes?`, `prepend`, `reversed`)

Also add (using direct recursion, not fold):

- `nth`, `at`
- `take`, `drop`

Verify all tests pass.

### Step 5: Implement Fold as LLVM Built-in

Re-implement `fold` as a built-in using LLVM IR with a non-recursive loop:

```ruby
# lib/stone/builtins/list_fold.rb
module Stone
  module Builtins
    class ListFold
      def self.call(builder, mod, list_ptr, acc, func_ptr)
        # LLVM IR: loop that traverses the list
        # entry:
        #   br loop
        # loop:
        #   current = phi [list_ptr, entry], [next, loop_body]
        #   accumulator = phi [acc, entry], [new_acc, loop_body]
        #   is_null = icmp eq current, null
        #   br is_null, done, loop_body
        # loop_body:
        #   first = extractvalue current, 0
        #   rest = extractvalue current, 1
        #   new_acc = call func_ptr(accumulator, first)
        #   br loop
        # done:
        #   ret accumulator
      end
    end
  end
end
```

This eliminates recursion entirely. The pure Stone `fold` definition is replaced by the built-in.

### Step 6: Implement `++` Operator for Concat (Optional)

Add `++` as a binary operator that desugars to `concat`:

```stone
++ := concat
list1 ++ list2   # Desugars to: ++(list1, list2)
```

This may require grammar changes to add `++` as an operator. If the grammar work is non-trivial, defer to a separate prompt.

### Step 7: Advanced Operations (Deferred)

These can be implemented in future prompts:

- `sorted`, `sorted_by` — requires comparison infrastructure
- `flatten` — requires nested list support
- `zip` — combines two lists element-wise
- `each` — side-effectful iteration (requires I/O or mutability story)

## Test Cases

These tests assume the List type and all operations are defined in the prelude. Each test only sets up data and calls operations — it does not redefine implementations.

The List type definition and all `List@` operations (`empty?`, `fold`, `reduce`, `length`, `nth`, `at`, `first`, `rest`, `last`, `prepend`, `append`, `concat`, `reversed`, `map`, `filter`, `select`, `reject`, `find`, `detect`, `includes?`, `any?`, `some?`, `all?`, `none?`, `uniq`, `take`, `drop`, and aliases) are expected to be loaded from the prelude before these tests run.

### Basic List Construction

```ruby
RSpec.describe "List Type" do
  describe "definition" do
    it "can define a generic List type as a sum type" do
      code = <<~STONE
        List :: (Type) -> Type
        List := λ(T) { Null | Record(first :: T, rest :: List(T)) }
        List
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end

    it "can instantiate a List type for Int" do
      code = <<~STONE
        IntList := List(Int)
        IntList
      STONE
      expect { Stone.eval(code) }.not_to raise_error
    end
  end

  describe "construction" do
    it "can create a single-element list" do
      code = <<~STONE
        IntList := List(Int)
        list := IntList(42, NULL)
        list.first
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "can create a multi-element list" do
      code = <<~STONE
        IntList := List(Int)
        list := IntList(1, IntList(2, IntList(3, NULL)))
        list.first
      STONE
      expect(Stone.eval(code)).to eq(1)
    end

    it "uses NULL as empty list" do
      code = <<~STONE
        IntList := List(Int)
        list := IntList(1, NULL)
        list.rest == NULL
      STONE
      expect(Stone.eval(code)).to be true
    end

    it "can traverse list elements" do
      code = <<~STONE
        IntList := List(Int)
        list := IntList(1, IntList(2, IntList(3, NULL)))
        list.rest.rest.first
      STONE
      expect(Stone.eval(code)).to eq(3)
    end
  end
end
```

### Empty Checks

```ruby
RSpec.describe "List@empty?" do
  it "returns TRUE for NULL" do
    code = <<~STONE
      List@empty?(NULL)
    STONE
    expect(Stone.eval(code)).to be true
  end

  it "returns FALSE for non-empty list" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(42, NULL)
      List@empty?(list)
    STONE
    expect(Stone.eval(code)).to be false
  end
end
```

### Fold

```ruby
RSpec.describe "List@fold" do
  it "returns initial value for empty list" do
    code = <<~STONE
      List@fold(NULL, 0, λ(acc, x) { acc + x })
    STONE
    expect(Stone.eval(code)).to eq(0)
  end

  it "sums all elements" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(1, IntList(2, IntList(3, NULL)))
      List@fold(list, 0, λ(acc, x) { acc + x })
    STONE
    expect(Stone.eval(code)).to eq(6)
  end

  it "can compute product" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(2, IntList(3, IntList(4, NULL)))
      List@fold(list, 1, λ(acc, x) { acc * x })
    STONE
    expect(Stone.eval(code)).to eq(24)
  end
end
```

### Reduce

```ruby
RSpec.describe "List@reduce" do
  it "returns NULL for empty list" do
    code = <<~STONE
      List@reduce(NULL, λ(acc, x) { acc + x })
    STONE
    expect(Stone.eval(code)).to be_nil
  end

  it "reduces without initial value" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(1, IntList(2, IntList(3, NULL)))
      List@reduce(list, λ(acc, x) { acc + x })
    STONE
    expect(Stone.eval(code)).to eq(6)
  end

  it "returns the single element for a one-element list" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(42, NULL)
      List@reduce(list, λ(acc, x) { acc + x })
    STONE
    expect(Stone.eval(code)).to eq(42)
  end
end
```

### Length

```ruby
RSpec.describe "List@length" do
  it "returns 0 for empty list" do
    code = <<~STONE
      List@length(NULL)
    STONE
    expect(Stone.eval(code)).to eq(0)
  end

  it "returns correct length" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(1, IntList(2, IntList(3, NULL)))
      List@length(list)
    STONE
    expect(Stone.eval(code)).to eq(3)
  end
end
```

### Last

```ruby
RSpec.describe "List@last" do
  it "returns NULL for empty list" do
    code = <<~STONE
      List@last(NULL)
    STONE
    expect(Stone.eval(code)).to be_nil
  end

  it "returns last element" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(1, IntList(2, IntList(3, NULL)))
      List@last(list)
    STONE
    expect(Stone.eval(code)).to eq(3)
  end
end
```

### Nth and Indexing

```ruby
RSpec.describe "List@nth" do
  it "returns first element at index 1" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(10, IntList(20, IntList(30, NULL)))
      List@nth(list, 1)
    STONE
    expect(Stone.eval(code)).to eq(10)
  end

  it "returns middle element" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(10, IntList(20, IntList(30, NULL)))
      List@nth(list, 2)
    STONE
    expect(Stone.eval(code)).to eq(20)
  end

  it "returns last element" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(10, IntList(20, IntList(30, NULL)))
      List@nth(list, 3)
    STONE
    expect(Stone.eval(code)).to eq(30)
  end

  it "returns NULL for out-of-bounds index" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(10, IntList(20, NULL))
      List@nth(list, 5) == NULL
    STONE
    expect(Stone.eval(code)).to be true
  end
end
```

### Prepend, Append, Concat

```ruby
RSpec.describe "List building operations" do
  describe "List@prepend" do
    it "adds element to head of list" do
      code = <<~STONE
        IntList := List(Int)
        list := IntList(2, IntList(3, NULL))
        result := List@prepend(list, 1)
        result.first
      STONE
      expect(Stone.eval(code)).to eq(1)
    end

    it "prepend to empty list creates single-element list" do
      code = <<~STONE
        IntList := List(Int)
        result := List@prepend(NULL, 42)
        result.first
      STONE
      expect(Stone.eval(code)).to eq(42)
    end
  end

  describe "List@append" do
    it "adds element to tail of list" do
      code = <<~STONE
        IntList := List(Int)
        list := IntList(1, IntList(2, NULL))
        result := List@append(list, 3)
        result.rest.rest.first
      STONE
      expect(Stone.eval(code)).to eq(3)
    end
  end

  describe "List@concat" do
    it "concatenates two lists" do
      code = <<~STONE
        IntList := List(Int)
        a := IntList(1, IntList(2, NULL))
        b := IntList(3, IntList(4, NULL))
        result := List@concat(a, b)
        List@length(result)
      STONE
      expect(Stone.eval(code)).to eq(4)
    end

    it "preserves element order" do
      code = <<~STONE
        IntList := List(Int)
        a := IntList(1, IntList(2, NULL))
        b := IntList(3, IntList(4, NULL))
        result := List@concat(a, b)
        result.rest.rest.first
      STONE
      expect(Stone.eval(code)).to eq(3)
    end

    it "concat with empty list returns other list" do
      code = <<~STONE
        IntList := List(Int)
        b := IntList(3, IntList(4, NULL))
        result := List@concat(NULL, b)
        result.first
      STONE
      expect(Stone.eval(code)).to eq(3)
    end
  end
end
```

### Map

```ruby
RSpec.describe "List@map" do
  it "returns empty list when mapping over empty list" do
    code = <<~STONE
      List@map(NULL, λ(x) { x * 2 }) == NULL
    STONE
    expect(Stone.eval(code)).to be true
  end

  it "applies function to all elements" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(1, IntList(2, IntList(3, NULL)))
      doubled := List@map(list, λ(x) { x * 2 })
      doubled.first
    STONE
    expect(Stone.eval(code)).to eq(2)
  end

  it "preserves element order" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(1, IntList(2, IntList(3, NULL)))
      doubled := List@map(list, λ(x) { x * 2 })
      doubled.rest.rest.first
    STONE
    expect(Stone.eval(code)).to eq(6)
  end
end
```

### Filter/Select/Reject

```ruby
RSpec.describe "List@filter" do
  it "filters elements matching predicate" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(1, IntList(2, IntList(3, IntList(4, NULL))))
      evens := List@filter(list, λ(x) { x % 2 == 0 })
      evens.first
    STONE
    expect(Stone.eval(code)).to eq(2)
  end

  it "returns empty list when nothing matches" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(1, IntList(3, IntList(5, NULL)))
      result := List@filter(list, λ(x) { x % 2 == 0 })
      result == NULL
    STONE
    expect(Stone.eval(code)).to be true
  end
end

RSpec.describe "List@reject" do
  it "excludes elements matching predicate" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(1, IntList(2, IntList(3, IntList(4, NULL))))
      odds := List@reject(list, λ(x) { x % 2 == 0 })
      odds.first
    STONE
    expect(Stone.eval(code)).to eq(1)
  end
end
```

### Find and Search

```ruby
RSpec.describe "List@find" do
  it "returns first matching element" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(1, IntList(2, IntList(3, NULL)))
      List@find(list, λ(x) { x > 1 })
    STONE
    expect(Stone.eval(code)).to eq(2)
  end

  it "returns NULL when nothing matches" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(1, IntList(2, IntList(3, NULL)))
      List@find(list, λ(x) { x > 10 }) == NULL
    STONE
    expect(Stone.eval(code)).to be true
  end
end

RSpec.describe "List@includes?" do
  it "returns TRUE when element is in list" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(1, IntList(2, IntList(3, NULL)))
      List@includes?(list, 2)
    STONE
    expect(Stone.eval(code)).to be true
  end

  it "returns FALSE when element is not in list" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(1, IntList(2, IntList(3, NULL)))
      List@includes?(list, 99)
    STONE
    expect(Stone.eval(code)).to be false
  end
end

RSpec.describe "List@any? and List@all?" do
  it "any? returns TRUE when at least one matches" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(1, IntList(2, IntList(3, NULL)))
      List@any?(list, λ(x) { x > 2 })
    STONE
    expect(Stone.eval(code)).to be true
  end

  it "any? returns FALSE when none match" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(1, IntList(2, IntList(3, NULL)))
      List@any?(list, λ(x) { x > 10 })
    STONE
    expect(Stone.eval(code)).to be false
  end

  it "any? returns FALSE for empty list" do
    code = <<~STONE
      List@any?(NULL, λ(x) { x > 0 })
    STONE
    expect(Stone.eval(code)).to be false
  end

  it "all? returns TRUE when all match" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(1, IntList(2, IntList(3, NULL)))
      List@all?(list, λ(x) { x > 0 })
    STONE
    expect(Stone.eval(code)).to be true
  end

  it "all? returns FALSE when any does not match" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(1, IntList(2, IntList(3, NULL)))
      List@all?(list, λ(x) { x > 1 })
    STONE
    expect(Stone.eval(code)).to be false
  end

  it "all? returns TRUE for empty list (vacuous truth)" do
    code = <<~STONE
      List@all?(NULL, λ(x) { x > 100 })
    STONE
    expect(Stone.eval(code)).to be true
  end
end
```

### Reversed

```ruby
RSpec.describe "List@reversed" do
  it "reverses a list" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(1, IntList(2, IntList(3, NULL)))
      result := List@reversed(list)
      result.first
    STONE
    expect(Stone.eval(code)).to eq(3)
  end

  it "reversing empty list returns empty list" do
    code = <<~STONE
      List@reversed(NULL) == NULL
    STONE
    expect(Stone.eval(code)).to be true
  end
end
```

### Take and Drop

```ruby
RSpec.describe "List@take and List@drop" do
  it "take returns first n elements" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(1, IntList(2, IntList(3, IntList(4, NULL))))
      result := List@take(list, 2)
      List@length(result)
    STONE
    expect(Stone.eval(code)).to eq(2)
  end

  it "drop skips first n elements" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(1, IntList(2, IntList(3, IntList(4, NULL))))
      result := List@drop(list, 2)
      result.first
    STONE
    expect(Stone.eval(code)).to eq(3)
  end
end
```

### Uniq

```ruby
RSpec.describe "List@uniq" do
  it "removes duplicate elements" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(1, IntList(2, IntList(1, IntList(3, IntList(2, NULL)))))
      result := List@uniq(list)
      List@length(result)
    STONE
    expect(Stone.eval(code)).to eq(3)
  end

  it "preserves first-occurrence order" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(3, IntList(1, IntList(2, IntList(1, NULL))))
      result := List@uniq(list)
      result.first
    STONE
    expect(Stone.eval(code)).to eq(3)
  end
end
```

### None?

```ruby
RSpec.describe "List@none?" do
  it "returns TRUE when no elements match" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(1, IntList(2, IntList(3, NULL)))
      List@none?(list, λ(x) { x > 10 })
    STONE
    expect(Stone.eval(code)).to be true
  end

  it "returns FALSE when any element matches" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(1, IntList(2, IntList(3, NULL)))
      List@none?(list, λ(x) { x > 2 })
    STONE
    expect(Stone.eval(code)).to be false
  end
end
```

### At (Zero-Indexed)

```ruby
RSpec.describe "List@at" do
  it "returns element at zero-based index" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(10, IntList(20, IntList(30, NULL)))
      List@at(list, 0)
    STONE
    expect(Stone.eval(code)).to eq(10)
  end

  it "returns second element at index 1" do
    code = <<~STONE
      IntList := List(Int)
      list := IntList(10, IntList(20, IntList(30, NULL)))
      List@at(list, 1)
    STONE
    expect(Stone.eval(code)).to eq(20)
  end
end
```

### Tests Not Included

The following operations are defined in the Desired State but do not have test cases in this prompt:

- **Aliases** (`select`, `detect`, `some?`, `head`, `tail`, `car`, `cdr`, `size`, `count`): These are simple assignments (e.g., `List@select := List@filter`). Add at least one smoke test per alias group during implementation to verify they resolve correctly.
- **`List@first` and `List@rest` methods** (NULL-safe wrappers): The record fields `.first` and `.rest` are tested extensively. The NULL-safe method wrappers should be tested during implementation.

## Files to Create

1. `spec/language/lists/list_spec.rb` — Integration tests for List type definition and construction
2. `spec/language/lists/list_operations_spec.rb` — Tests for all list operations
3. `lib/stone/builtins/list_fold.rb` — LLVM built-in fold implementation (Step 5)

## Files to Modify

1. `lib/stone/prelude.stone` (or equivalent) — Add List type definition and all operations
2. `lib/stone/built_ins.rb` — Register fold built-in (Step 5)

## Acceptance Criteria

- [ ] List type can be defined as `λ(T) { Null | Record(first :: T, rest :: List(T)) }`
- [ ] Can create lists with multiple elements
- [ ] `NULL` represents the empty list (Null variant)
- [ ] `List@empty?` works correctly
- [ ] `List@fold` reduces list to a single value
- [ ] `List@reduce` works without initial value (uses first element)
- [ ] `List@length` returns correct count (via fold)
- [ ] `List@nth` accesses elements by 1-based index
- [ ] `List@at` accesses elements by 0-based index
- [ ] `List@first`, `List@last`, `List@rest` work
- [ ] `List@prepend` adds element to head (O(1))
- [ ] `List@append` adds element to tail (O(n))
- [ ] `List@concat` concatenates two lists (O(n))
- [ ] `List@map` transforms all elements (via fold)
- [ ] `List@filter`/`List@select` filters by predicate (via fold)
- [ ] `List@reject` excludes matching elements
- [ ] `List@find`/`List@detect` returns first matching element (via fold)
- [ ] `List@includes?` checks membership (via fold)
- [ ] `List@any?`/`List@some?` and `List@all?` work correctly (via fold)
- [ ] `List@none?` works correctly
- [ ] `List@reversed` reverses list order (via fold)
- [ ] `List@take` and `List@drop` work
- [ ] `List@uniq` removes duplicates (via fold)
- [ ] LLVM built-in fold is non-recursive (Step 5)
- [ ] All tests pass
- [ ] `make test` passes
- [ ] `make lint` passes

## Gotchas and Challenges

### 1. Recursion Depth Limits

- Deep lists may cause stack overflow with pure Stone `fold`
- Solution: Step 5 re-implements fold as an LLVM built-in with a loop
- Until then, test with reasonably-sized lists (< 100 elements)

### 2. Fold Builds Lists in Reverse

Operations that build new lists using `fold` + `prepend` produce results in reverse order (because `prepend` adds to the head, and `fold` processes left-to-right). Most operations need a final `reversed` call:

```stone
# Without reverse: fold over [1,2,3] with prepend gives [3,2,1]
# With reverse: gives [1,2,3] — correct order
List@map := λ(this, func) {
  List@reversed(List@fold(this, NULL, λ(acc, elem) { List@prepend(acc, func(elem)) }))
}
```

This doubles the traversal (O(2n) instead of O(n)) but is correct and simple.

### 3. No Short-Circuit in Fold

`fold` always traverses the entire list. Operations like `find`, `any?`, `includes?` cannot exit early. The fold-based implementations are still correct but do unnecessary work after finding the answer.

A future optimization: implement a `fold_while` or similar short-circuiting variant.

### 4. Type Parameter `T` in Methods

Methods like `prepend` need to construct `List(T)(value, this)`. This requires the implicit type passing mechanism from generic types. If `T` isn't available in the method body, we may need to use the concrete type directly (e.g., `IntList(value, this)`).

See `docs/prompts/generic-types.md` Decision 3 (Implicit Type Passing).

### 5. Construction Is Verbose

```stone
IntList(1, IntList(2, IntList(3, IntList(4, IntList(5, NULL)))))
```

- Very tedious for longer lists
- Solution: Varargs (future feature) would allow `List(Int)(1, 2, 3, 4, 5)`

### 6. Lack of Pattern Matching

Without pattern matching, we use `if(this.empty?, ...)` for dispatch:

```stone
# Would be nice:
match(list):
  | NULL -> 0
  | Record(first, rest) -> 1 + length(rest)

# Instead we use:
if(list.empty?, { 0 }, { 1 + length(list.rest) })
```

Pattern matching is a future feature.

### 7. `find` Returns NULL for Not-Found AND for Empty List

`find` returns `NULL` both when the predicate never matches and when the list is empty. This is ambiguous if `NULL` is a valid element. For now this is acceptable since `List(T)` where `T` includes `Null` is an unusual case.

## Opportunities

### 1. Showcase Functional Programming

- Lists are THE fundamental functional data structure
- Demonstrates immutability, recursion, higher-order functions
- `fold` as universal operation is a powerful concept

### 2. Standard Library Foundation

- Once Lists work, can build Maps, Sets, Trees similarly
- All collection types can share the fold-based pattern

### 3. Test Language Completeness

- If Lists work well, Stone can express real algorithms
- Good benchmark of language expressiveness
- Exposes gaps in type system, stdlib, etc.

### 4. Performance Baseline

- Compare fold-based operations against hand-written recursion
- Measure overhead of reverse-then-prepend pattern
- Use to justify LLVM built-in fold optimization

### 5. Future: Lazy Lists

```stone
# Infinite lists via lazy evaluation
naturals := LazyList(1, λ() { naturals.map(λ(n) { n + 1 }) })
```

### 6. Future: `++` Operator

```stone
list1 ++ list2   # Syntactic sugar for List@concat(list1, list2)
```

### 7. Future: List Comprehensions

```stone
[x * 2 | x <- numbers, x.positive?]
# Desugars to: numbers.filter(λ(x) { x.positive? }).map(λ(x) { x * 2 })
```

## Relationship to Other Features

### Prerequisites

- **Sum types** (`docs/prompts/sum-types.md`): Expression-level `|` for defining `Null | Record(...)`
- **Records**: Must work with recursive references
- **Lambdas**: Required for higher-order operations (fold, map, filter, etc.)
- **NULL handling**: `Null` type with `NULL` singleton
- **Generic types**: `λ(T) { ... }` for parameterized list type

### Enables

- Collection algorithms (sorting, searching, grouping)
- Functional programming patterns (map/filter/reduce pipelines)
- Real-world Stone programs
- Testing language expressiveness

### Future Enhancements

- Varargs for easy list construction: `List(Int)(1, 2, 3, 4)`
- `++` operator for concat
- Lazy evaluation for infinite lists
- Pattern matching for cleaner list code
- Parallel operations: `pmap`, `pfilter`
- Tail-call optimization for deeper recursion (general, not just fold)
- Array literal syntax: `[1, 2, 3]`
- Short-circuiting fold variant (`fold_while`)

## Notes

- Start simple: get basic construction and access working first
- Fold is critical — everything else builds on it
- The pure Stone fold is the initial implementation; LLVM built-in comes later
- Deep recursion is a real concern — test with reasonably-sized lists until LLVM fold is in place
- With ML-style generics, syntax is `List(Int)` not `List[Int]`
- The `reduce` vs `fold` distinction: `fold` takes 3 args (list, initial, func); `reduce` takes 2 (list, func) and uses first element as initial
- `prepend` is O(1), `append` is O(n) — this is inherent to cons lists
- The reverse-then-prepend pattern is idiomatic for building lists with fold

## Related Reading

- [Purely Functional Data Structures](https://www.cambridge.org/core/books/purely-functional-data-structures/0409255DA1B48FA731859AC72E34D494) (Okasaki)
- [Learn You a Haskell: Lists](http://learnyouahaskell.com/starting-out#an-intro-to-lists)
- [Racket List Documentation](https://docs.racket-lang.org/reference/pairs.html)
- [Scheme R7RS List Procedures](https://standards.scheme.org/official/r7rs.pdf)
- [OCaml Lists](https://ocaml.org/docs/lists)
- Existing Stone prompt: `docs/prompts/sum-types.md` — prerequisite for List definition
- Existing Stone prompt: `docs/prompts/generic-types.md` — generic type mechanism
- Existing Stone prompt: `docs/prompts/string-properties.md` — similar operation patterns

## Wrap-Up

Once you've completed the implementation:

- Update this file with any as-built changes we made to the design
    - Don't overwrite original design decisions
- Include this updated file as part of the commit
- Add any lessons learned to your "memory"
- Run the `/retro` command
