# Generic Types (Parametric Polymorphism)

## Overview

Implement generic/parametric types in Stone using a functional approach where **all types are constructor functions** and **generic types are functions that return types**. This treats types as first-class values, enabling type-safe, reusable data structures like `List(Int)`, `Maybe(String)`, `Pair(Int, Bool)`, etc.

Ask any questions up front, as much as possible. Once your questions have been answered, you may continue all the way to committing.

## Prerequisites

**Required (implement before generics):**

1. **NULL literal** - For terminating recursive structures
2. **Type annotation scoping** - T in `first :: T` resolves from scope
3. **Function type syntax** - `(A) -> B` in type signatures
4. **Recursive record types** - Self-referential types like IntList

**Recommended:**

- Record as constructor function - should be completed
- Static type system for type signatures
- Type checking arguments - validate types at call sites

## Goals

1. Treat all types as first-class values with kind `Type`
2. Support type-level functions: `List :: (Type) -> Type`
3. Generic types as lambdas: `List := λ(T) { Record(first :: T, rest :: List(T) | NULL) }`
4. Type instantiation via function application: `List(Int)`
5. Enable recursive generic types: `List(T)` references `List(T)` in its definition
6. **Implicit type passing**: Methods on generic types automatically receive type parameters
7. Foundation for implementing generic List type and other collections

## Core Philosophy: Types as Values, Generics as Functions

**Key Insight:** In Stone, types ARE constructor functions. Generic types are simply functions that take types and return types.

```stone
# Built-in types have kind Type
Int :: Type
Bool :: Type
String :: Type

# Generic types are functions from Type to Type
List :: (Type) -> Type
List := λ(T) { Record(first :: T, rest :: List(T) | NULL) }

# Instantiation is function application
IntList :: Type
IntList := List(Int)
IntList == List(Int)  # TRUE

# Using the constructor
nums :: IntList
nums := IntList(42, NULL)
nums2 :: List(Int)
nums2 := List(Int)(42, NULL)
nums == nums2  # TRUE
```

## Design Decisions (Finalized)

### Decision 1: ML-Style Parentheses Syntax

We use **ML-style parentheses** for type application:

```stone
List(Int)
Pair(String, Bool)
Maybe(Int)
```

**Not** square or angle brackets (`List[Int]`, `List<Int>`).

**Advantages:**

- ✅ No new syntax needed - just function calls
- ✅ Types are first-class values
- ✅ Consistent with Stone's functional nature
- ✅ Enables higher-order type operations naturally

### Decision 2: Nested Lambdas (No Currying Syntax)

We do NOT add special currying syntax. Instead, use nested lambdas:

```stone
# For a curried function:
add := λ(x) { λ(y) { x + y } }

# NOT: λ(x)(y) { x + y }
```

The type signature reflects the nested structure:

```stone
add :: (Int) -> ((Int) -> Int)
```

The parentheses in the type correspond to the lambda nesting.

### Decision 3: Implicit Type Passing

Methods on generic types automatically have access to the type parameter `T` from the generic type's definition.

```stone
List :: (Type) -> Type
List := λ(T) { Record(first :: T, rest :: List(T) | NULL) }

# T is implicitly in scope for all List@methods
List@empty? := λ(this) { this == NULL }           # No T needed
List@sorted := λ(this) { ... T@<=(a, b) ... }     # Uses T (should this be `this.T` instead of just `T`?)
```

**How it works:**

1. When `List` is defined as `λ(T) { ... }`, T becomes available to all `List@methods`
2. Compiler scans method body for `T` usage (`T@...`, `T(...)`, etc.)
3. If T is used, compiler transforms method to `λ(T) { λ(this) { ... } }`
4. If T is not used, method stays as `λ(this) { ... }`

**At call sites:**

```stone
IntList := List(Int)
list := IntList(1, IntList(2, NULL))

# Compiler transforms based on whether method needs T:
IntList@empty?(list)   →  List@empty?(list)        # Direct call
IntList@sorted(list)   →  List@sorted(Int)(list)   # Type injected
```

### Decision 4: "Only When Needed" Type Passing

The compiler only adds implicit type parameters when the method body uses them:

- **T is needed if:** Body contains `T@...`, `T(...)`, `T.something`, or other T usage
- **T is not needed if:** Body only uses `this`, `NULL`, etc.

This avoids overhead for simple methods like `empty?`.

Fallback: If implementation gets complex, we can switch to "always pass T".

### Decision 5: Single Namespace with Shadowing

Types and values share the same namespace:

- `T` in a lambda parameter is the same `T` referenced in type annotations
- Shadowing works normally (inner scope shadows outer)
- **Warning** when implicit type parameters (like `T` from `List`) are shadowed

```stone
List := λ(T) {
  T := 42  # Warning: T shadows implicit type parameter
  ...
}
```

### Decision 6: Monomorphization at FFI Boundaries

Internally, Stone uses implicit type passing for polymorphism.
At FFI boundaries, we monomorphize to concrete types:

```stone
# Internal: polymorphic
List@map(T)(list, func)

# Exported for C/FFI: monomorphized
List_Int_map(list, func)
List_String_map(list, func)
```

This maintains FFI compatibility with standard layouts.

### Decision 7: Type Instantiation Registry

When `List(Int)` is used, it's added to a type registry:

```ruby
types["List(Int)"] = { base: "List", params: { "T" => "Int" } }
```

This enables:

- Looking up type parameters at call sites
- Determining which T to pass for `IntList@sorted`
- Caching instantiated types

## Implementation Strategy

### Step 0: Write tests

As always, we do TDD and write test cases before we start coding.

### Step 1: Check Prerequisites

Check that these prerequisites have been completed:

1. NULL literal
2. Type annotation scoping  
3. Function type syntax
4. Recursive record types

### Step 2: Type-Level Lambda Evaluation

When a lambda's parameter is used in a type context (Record field types), evaluate at compile time:

```stone
List := λ(T) { Record(first :: T, rest :: List(T) | NULL) }
IntList := List(Int)
# ^ Evaluates to: Record(first :: Int, rest :: IntList | NULL)
```

Implementation:

1. Detect type-level lambda: signature is `(Type) -> Type` or body is a Record
2. When called with a type argument, substitute T in the body
3. Return the resulting Record definition

### Step 3: Type Instantiation Tracking

Track instantiated types:

```ruby
# In llvm_module extensions
def type_instantiations
  @type_instantiations ||= {}
end

def register_type_instantiation(name, base_type, params)
  type_instantiations[name] = { base: base_type, params: params }
end

def get_type_params(name)
  type_instantiations[name]&.dig(:params)
end
```

### Step 4: Method Signature Analysis

When defining `List@foo`, analyze whether T is needed:

```ruby
def needs_type_param?(method_body, type_param_names)
  # Scan AST for references to T, T@..., T(...), etc.
  TypeParamScanner.scan(method_body, type_param_names)
end
```

### Step 5: Call Site Transformation

Transform method calls to inject type parameters:

```ruby
# When processing: IntList@sorted(list)
# 1. Look up IntList → List(Int), so T = Int
# 2. Look up List@sorted → needs T
# 3. Transform to: List@sorted(Int)(list)
```

### Step 6: Function Signature Properties

Store type parameter info on functions:

```ruby
def register_function_type_params(name, type_params)
  # type_params = ["T"] for List@sorted
  # type_params = [] for List@empty?
  function_type_params[name] = type_params
end
```

## Test Cases

### Basic Generic Type

```ruby
RSpec.describe "Generic Types" do
  it "allows defining a generic type as a type-level function" do
    code = <<~STONE
      Box :: (Type) -> Type
      Box := λ(T) { Record(value :: T) }
      Box
    STONE
    expect { Stone.eval(code) }.not_to raise_error
  end

  it "allows instantiating a generic type via function application" do
    code = <<~STONE
      Box :: (Type) -> Type
      Box := λ(T) { Record(value :: T) }
      IntBox :: Type
      IntBox := Box(Int)
      IntBox
    STONE
    expect { Stone.eval(code) }.not_to raise_error
  end

  it "can create instances of instantiated generic types" do
    code = <<~STONE
      Box :: (Type) -> Type
      Box := λ(T) { Record(value :: T) }
      IntBox := Box(Int)
      b := IntBox(42)
      b.value
    STONE
    expect(Stone.eval(code)).to eq(42)
  end

  it "supports multiple instantiations of same generic type" do
    code = <<~STONE
      Box :: (Type) -> Type
      Box := λ(T) { Record(value :: T) }
      IntBox := Box(Int)
      StringBox := Box(String)
      ib := IntBox(42)
      sb := StringBox("hello")
      sb.value
    STONE
    expect(Stone.eval(code)).to eq("hello")
  end
end
```

### Recursive Generic Types

```ruby
RSpec.describe "Recursive Generic Types" do
  it "allows recursive reference in generic type" do
    code = <<~STONE
      List :: (Type) -> Type
      List := λ(T) { Record(first :: T, rest :: List(T) | NULL) }
      List
    STONE
    expect { Stone.eval(code) }.not_to raise_error
  end

  it "can create a linked list" do
    code = <<~STONE
      List :: (Type) -> Type
      List := λ(T) { Record(first :: T, rest :: List(T) | NULL) }
      IntList := List(Int)
      list := IntList(1, IntList(2, IntList(3, NULL)))
      list.rest.first
    STONE
    expect(Stone.eval(code)).to eq(2)
  end
end
```

### Implicit Type Passing

```ruby
RSpec.describe "Implicit Type Passing" do
  it "methods without T usage work directly" do
    code = <<~STONE
      List :: (Type) -> Type
      List := λ(T) { Record(first :: T, rest :: List(T) | NULL) }
      List@empty? := λ(this) { this == NULL }
      
      IntList := List(Int)
      list := IntList(42, NULL)
      IntList@empty?(list)
    STONE
    expect(Stone.eval(code)).to be false
  end

  it "methods using T receive it implicitly" do
    code = <<~STONE
      List :: (Type) -> Type
      List := λ(T) { Record(first :: T, rest :: List(T) | NULL) }
      
      # This method uses T as a constructor
      List@prepend := λ(this, value) {
        T(value, this)
      }
      
      IntList := List(Int)
      list := IntList(2, NULL)
      newList := IntList@prepend(list, 1)
      newList.first
    STONE
    expect(Stone.eval(code)).to eq(1)
  end
end
```

### Multiple Type Parameters

```ruby
RSpec.describe "Multiple Type Parameters" do
  it "supports two type parameters" do
    code = <<~STONE
      Pair :: (Type) -> ((Type) -> Type)
      Pair := λ(K) { λ(V) { Record(key :: K, value :: V) } }
      IntStringPair := Pair(Int)(String)
      p := IntStringPair(42, "answer")
      p.value
    STONE
    expect(Stone.eval(code)).to eq("answer")
  end
end
```

## Files to Create

1. `lib/stone/type_evaluator.rb` - Compile-time type expression evaluation
2. `lib/stone/type_param_scanner.rb` - Scan AST for type parameter usage
3. `spec/language/types/generic_types_spec.rb` - Integration tests

## Files to Modify

1. `lib/stone/grammar.rb` - Ensure type annotation grammar supports generics
2. `lib/stone/transform.rb` - Transform type-level lambdas
3. `lib/stone/ast/lambda.rb` - Handle type-level lambda evaluation
4. `lib/stone/ast/function_call.rb` - Handle type application
5. `lib/stone/ast/constant_definition.rb` - Register type instantiations
6. `lib/stone/ast/computed_property_definition.rb` - Analyze for T usage, transform if needed
7. `lib/extensions/llvm_module.rb` - Type instantiation registry, function type params

## Acceptance Criteria

- [ ] `Box :: (Type) -> Type` defines a generic type
- [ ] `Box(Int)` instantiates the generic type
- [ ] `IntBox(42).value` returns 42
- [ ] Multiple instantiations work independently
- [ ] Recursive generic types work: `List(T)` referencing `List(T)`
- [ ] Methods without T usage work without transformation
- [ ] Methods using T receive it implicitly
- [ ] Call sites inject correct type based on instantiation
- [ ] Type parameter shadowing produces warning
- [ ] All existing tests pass
- [ ] `make test` passes
- [ ] `make lint` passes

## Gotchas and Challenges

### 1. Type-Level vs Value-Level Distinction

```stone
double :: (Int) -> Int          # Value-level function
double := λ(x) { x * 2 }

List :: (Type) -> Type          # Type-level function
List := λ(T) { Record(...) }
```

**Solution:** Check if return type is `Type` or if body is a Record definition.

### 2. Compile-Time Evaluation

```stone
IntList := List(Int)  # Must evaluate at compile time!
```

Type-level function calls must be evaluated during compilation, not at runtime.

### 3. Recursive Type References

```stone
List := λ(T) { Record(first :: T, rest :: List(T) | NULL) }
#                                        ^^^^^^^ 
#                               References List while defining it!
```

**Solution:** Use lazy/forward references in type resolution.

### 4. Method T Scope

When defining `List@sorted`, how does T get in scope?

**Solution:** When processing `List@foo`, look up `List`'s definition and bind its type parameters to the method's scope.

### 5. Anonymous Type Instantiations

```stone
# No named IntList, using List(Int) directly
list := List(Int)(42, NULL)
```

**Solution:** Register `List(Int)` as an anonymous type instantiation.

## Relationship to Other Features

### Prerequisites

- **NULL literal**: For terminating recursive structures
- **Type annotation scoping**: T in annotations must resolve
- **Function type syntax**: For `(Type) -> Type` signatures
- **Recursive record types**: Foundation for generic recursive types

### Enables

- **Generic List type**: `List := λ(T) { Record(...) }`
- **Maybe/Option type**: `Maybe := λ(T) { Record(...) }`
- **Result/Either type**: Generic error handling
- **Type-safe collections**: Maps, Sets, Trees

### Future Enhancements

- **Type constraints**: `Ord(T) =>` for requiring operations
- **Higher-kinded types**: `Functor :: ((Type) -> Type) -> Constraint`
- **Type inference**: Infer T from usage
- **Union types**: `List(T) | NULL` properly typed

## Notes

- This approach is more complex but more elegant and powerful
- Implicit type passing avoids code explosion from full monomorphization
- Start with simple cases, add complexity incrementally
- FFI compatibility maintained via monomorphization at boundaries
- The term for passing types to methods is "implicit type passing"
- Types and values share a namespace; shadowing works normally

## Wrap-Up

Once you've completed the implementation:

- Update this file with any as-built changes we made to the design
- Include this updated file as part of the commit
- Add any lessons learned to your "memory"
- Run the `/retro` command
