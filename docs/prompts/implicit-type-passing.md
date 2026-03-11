# Implicit Type Passing for Generic Types

## Overview

Methods defined on generic types should automatically receive the type parameter
at call sites, without requiring the programmer to pass it explicitly.
This enables ergonomic APIs like `list.sorted()` where the sort implementation
knows the element type `T` without the caller specifying it.

## Current State

Generic types are implemented as type-level lambdas with substitution-based
instantiation:

```stone
List :: (Type) -> Type
List := λ(T) { Record(first :: T, rest :: List(T)) }
IntList := List(Int)
list := IntList(1, IntList(2, IntList(3, NULL)))
list.first  # => 1
```

Computed properties work on concrete types:

```stone
Int@abs := λ(self) { if(self > 0, { self }, { 0 - self }) }
x := -42
x.abs  # => 42
```

## Problem

To define a method like `sorted` on `List(T)`, the implementation needs to
know `T` so it can compare elements. Currently, there is no mechanism to:

1. Define computed properties on generic type instances
2. Pass type parameters to computed property implementations
3. Resolve the element type from a generic record instance

## Proposed Design

### Method Signatures on Generic Types

```stone
# Define a method on List that requires knowing T
List@sorted :: (List(T)) -> List(T)
List@sorted := λ(self) {
    # T is implicitly available here from the receiver's type
    # Implementation can use T for comparisons
}
```

### Implicit Type Resolution

When `list.sorted()` is called on a `List(Int)` instance:

1. Look up the receiver's concrete type: `List(Int)`
2. Extract the type arguments: `[Int]`
3. Match against the generic definition's parameters: `T = Int`
4. Make `T` available in the method body's scope

### Call Site Transformation

The compiler transforms `list.sorted()` into the equivalent of:

```stone
List@sorted(list)  # T resolved from list's type to Int
```

The type parameter `T` is resolved at compile time from the receiver's
record type registration, not passed as a runtime argument.

**HELP**: I'm not sure that's what I want. I don't see how all calls to List@sorted
would know what T is unless it's passed in some way. I thought that was the point of this design.

### Method Signature Analysis

For `List@sorted`, the compiler:

1. Recognizes `List` as a generic type with parameter `T`
2. Parses the computed property name to extract the base type
3. When the method is called, resolves `T` from the receiver's instantiated type

### "Only When Needed" Optimization

Type parameters should only be passed (or resolved) when the method body
actually uses them. A method like `List@length` that just counts elements
does not need `T`:

```stone
List@length :: (List(T)) -> Int
List@length := λ(self) {
    if(==(self.rest, NULL), { 1 }, { sum(1, self.rest.length) })
}
```

Since `T` is not referenced in the body, no type resolution is needed.
The compiler can detect this statically.

## Implementation Steps

0. **Write specs** - Follow TDD practices; write all the tests first.
Mark all the newly added tests as pending initially;
remove the pending flag as you attempt to pass each one.

1. **Computed property lookup for generic types** - When accessing `list.sorted`, resolve `List(Int)` back to its generic base `List` and look up `List@sorted`.

2. **Type argument extraction** - Given a canonical name like `"List(Int)"`, extract the base name `"List"` and type arguments `["Int"]`.

3. **Scope binding** - Before evaluating the method body, bind `T = Int` in the method's scope so field type annotations resolve correctly (only if `T` is used in the body).

4. **Signature validation** - Verify that the method's declared parameter types match the resolved concrete types. **HELP**: Is this necessary for implicit type passing?

5. **Update documentation** - Document the new feature in the language reference; make sure to update any documentation that no longer applies.

## Design Decisions

- Type parameters are resolved at compile time, not runtime
- No runtime type erasure; each instantiation has full type information
    - Question: What are the trade-offs here?
- Methods on generic types use the same computed property mechanism as
  methods on primitive types
- The generic base name is extracted from the canonical name string
  (e.g., `"List(Int)"` -> base `"List"`, args `["Int"]`)

## Dependencies

- Generic types (implemented)
- Computed properties (implemented)
- Method dispatch on record types (partially implemented)

## Wrap-Up

Once you've completed the implementation:

- Update this file with any as-built changes we made to the design
    - Don't overwrite original design decisions
- Include this updated file as part of the commit
- Add any lessons learned to your "memory"
- Run the `/retro` command
