# String Operators

## Overview

Implement operators for String manipulation in Stone.
The primary operator is concatenation using `++`.
Comparison operators for strings are also covered.

## Design Decisions

### Mixed Operator Detection

**Decision**: Transform-time error (after parsing, before LLVM generation).

When mixing `++` with arithmetic operators without parentheses (e.g., `"x" ++ "y" + "z"`),
the error is raised during the AST transformation phase. This follows the same pattern
as arithmetic operators.

### Operator vs Function Naming

**Decision**: Primitive functions use descriptive names; operators are Stone-level wrappers.

- `concat` is the primitive function for string concatenation
- `++` is a Stone-level operator that calls `concat`
- This allows `++` to potentially be redefined for other types (like lists)

## String Concatenation

### Operator: `++`

Concatenate two strings to produce a new string.

```stone
# Basic concatenation
"hello" ++ " " ++ "world"     # "hello world"
"foo" ++ "bar"                # "foobar"

# With empty strings
"" ++ "hello"                 # "hello"
"hello" ++ ""                 # "hello"
"" ++ ""                      # ""

# Chaining
"a" ++ "b" ++ "c" ++ "d"      # "abcd"
```

**Implementation**:

1. Allocate new string with combined length
2. Copy first string to new buffer
3. Copy second string after first
4. Return new string structure `{ ptr, length }`

**LLVM pseudocode**:

```llvm
%len1 = extractvalue { ptr, i64 } %s1, 1
%len2 = extractvalue { ptr, i64 } %s2, 1
%newlen = add i64 %len1, %len2

; Allocate new string
%newptr = call ptr @malloc(i64 %newlen)

; Copy s1
%ptr1 = extractvalue { ptr, i64 } %s1, 0
call void @memcpy(ptr %newptr, ptr %ptr1, i64 %len1)

; Copy s2 after s1
%offset = getelementptr i8, ptr %newptr, i64 %len1
%ptr2 = extractvalue { ptr, i64 } %s2, 0
call void @memcpy(ptr %offset, ptr %ptr2, i64 %len2)

; Return new string
%result = insertvalue { ptr, i64 } undef, ptr %newptr, 0
%result = insertvalue { ptr, i64 } %result, i64 %newlen, 1
```

**Properties**:

- Associative: `(a ++ b) ++ c` equals `a ++ (b ++ c)` in result (different intermediate allocations)
- Identity element: `""` (empty string)
- Not commutative: `"ab" ++ "cd" != "cd" ++ "ab"`

**Performance**: Each `++` creates a new allocation. For many concatenations, use StringBuilder:

```stone
# Inefficient: creates 3 intermediate strings
result := "a" ++ "b" ++ "c" ++ "d"

# Efficient: single buffer
sb := StringBuilder.new()
sb.append("a").append("b").append("c").append("d")
result := sb.to_string()
```

### Alternative: `concat` Method

Method form provides same functionality:

```stone
"hello".concat(" world")    # "hello world"
```

See String Properties document for details.

### Type Safety: String-Only Concatenation

`++` operator only works with strings. No implicit type conversion:

```stone
# String concatenation only
"Count: " ++ "42"           # OK: "Count: 42"

# No implicit conversion from other types
"Count: " ++ 42             # Error: can't concatenate Int to String

# Explicit conversion required
"Count: " ++ 42.to_string() # OK (when to_string available)

# Or use string interpolation
"Count: $(1)".interp(42)    # "Count: 42"
```

**Rationale**: Explicit conversions make intent clear and avoid ambiguity.

## String Comparison

String comparison operators return boolean results and use lexicographic (dictionary) ordering.

### Equality: `==`

Test if two strings have identical content.

```stone
"hello" == "hello"          # TRUE
"hello" == "Hello"          # FALSE (case-sensitive)
"hello" == "world"          # FALSE
"" == ""                    # TRUE

# Works with references
s1 := "test"
s2 := "test"
s1 == s2                    # TRUE
```

**Implementation**:

1. Compare lengths first (quick rejection)
2. If same length, byte-by-byte comparison using `memcmp`
3. Return TRUE if all bytes match

**LLVM pseudocode**:

```llvm
%len1 = extractvalue { ptr, i64 } %s1, 1
%len2 = extractvalue { ptr, i64 } %s2, 1
%len_eq = icmp eq i64 %len1, %len2
br i1 %len_eq, label %compare_bytes, label %not_equal

compare_bytes:
  %ptr1 = extractvalue { ptr, i64 } %s1, 0
  %ptr2 = extractvalue { ptr, i64 } %s2, 0
  %cmp = call i32 @memcmp(ptr %ptr1, ptr %ptr2, i64 %len1)
  %result = icmp eq i32 %cmp, 0
  br label %done

not_equal:
  br label %done

done:
  %result = phi i1 [ %result, %compare_bytes ], [ false, %not_equal ]
```

**Properties**:

- Reflexive: `s == s` is always TRUE
- Symmetric: `s1 == s2` implies `s2 == s1`
- Transitive: `s1 == s2` and `s2 == s3` implies `s1 == s3`

### Inequality: `!=` or `≠`

Test if two strings are different.

```stone
"hello" != "world"          # TRUE
"hello" != "hello"          # FALSE

# Unicode alternative
"hello" ≠ "world"           # TRUE
```

**Symbol**: `≠` (U+2260 NOT EQUAL TO)

**Implementation**: Return `not(s1 == s2)`

### Lexicographic Comparison

Compare strings alphabetically (byte-by-byte for ASCII).

#### Less Than: `<`

```stone
"abc" < "abd"               # TRUE (c comes before d)
"abc" < "abc"               # FALSE (equal)
"a" < "aa"                  # TRUE (shorter comes first as prefix)
"" < "a"                    # TRUE (empty is smallest)
"apple" < "banana"          # TRUE
```

**Implementation**:

1. Compare byte-by-byte until difference found
2. Return TRUE if s1's byte is less than s2's byte at first difference
3. If one string is prefix of other, shorter is less

**LLVM pseudocode**:

```llvm
%len1 = extractvalue { ptr, i64 } %s1, 1
%len2 = extractvalue { ptr, i64 } %s2, 1
%min_len = select i1 (icmp ult i64 %len1, %len2), i64 %len1, i64 %len2

%ptr1 = extractvalue { ptr, i64 } %s1, 0
%ptr2 = extractvalue { ptr, i64 } %s2, 0
%cmp = call i32 @memcmp(ptr %ptr1, ptr %ptr2, i64 %min_len)

%cmp_lt = icmp slt i32 %cmp, 0
%cmp_eq = icmp eq i32 %cmp, 0
%len_lt = icmp ult i64 %len1, %len2
%result = or i1 %cmp_lt, (and i1 %cmp_eq, %len_lt)
```

#### Less Than or Equal: `≤` or `<=`

```stone
"abc" ≤ "abc"               # TRUE
"abc" ≤ "abd"               # TRUE
"abd" ≤ "abc"               # FALSE

# ASCII alternative
"abc" <= "abd"              # TRUE
```

**Symbol**: `≤` (U+2264 LESS-THAN OR EQUAL TO)

**Implementation**: `(s1 < s2) ∨ (s1 == s2)` or direct comparison with `memcmp`

#### Greater Than: `>`

```stone
"xyz" > "abc"               # TRUE
"b" > "aaa"                 # TRUE (first char comparison)
"abc" > "abc"               # FALSE
```

**Implementation**: `s2 < s1`

#### Greater Than or Equal: `≥` or `>=`

```stone
"abc" ≥ "abc"               # TRUE
"abd" ≥ "abc"               # TRUE
"abc" ≥ "abd"               # FALSE

# ASCII alternative
"abd" >= "abc"              # TRUE
```

**Symbol**: `≥` (U+2265 GREATER-THAN OR EQUAL TO)

**Implementation**: `(s1 > s2) ∨ (s1 == s2)` or direct comparison with `memcmp`

### Comparison Properties

- Total ordering: every pair of strings can be compared
- Transitive: if `a < b` and `b < c` then `a < c`
- Antisymmetric: if `a ≤ b` and `b ≤ a` then `a == b`

### ASCII Assumption

For now, comparisons assume ASCII encoding and compare byte-by-byte. This works correctly for ASCII strings.

**Future**: Locale-aware string comparison for proper Unicode ordering (collation). Different languages have different sort orders.

## String Membership Methods

While there's no `in` operator syntax yet, membership testing is available via methods:

### Method: `contains?(substring)`

```stone
# Check if substring is present
"hello world".contains?("world")    # TRUE
"hello world".contains?("xyz")      # FALSE
"hello world".contains?("")         # TRUE (empty string always contained)
```

See String Properties document for implementation details.

### Method: `includes?(substring)`

Alias for `contains?`:

```stone
"hello world".includes?("world")    # TRUE
```

### Future: Element-Of Operator `∈`

```stone
# Potential future syntax
"world" ∈ "hello world"     # TRUE (substring membership)
"x" ∈ "hello"               # FALSE
```

**Symbol**: `∈` (U+2208 ELEMENT OF)

This would be syntactic sugar for `.contains?()` with reversed operands.

### Future: Contains Operator `∋`

```stone
# Potential future syntax (reverse of ∈)
"hello world" ∋ "world"     # TRUE
```

**Symbol**: `∋` (U+220B CONTAINS AS MEMBER)

Equivalent to `.contains?()`.

## Operator Summary Table

| Operator | Unicode | ASCII | Description      | Example        | Result   |
| -------- | ------- | ----- | ---------------- | -------------- | -------- |
| `++`     | —       | `++`  | Concatenation    | `"ab" ++ "cd"` | `"abcd"` |
| `==`     | —       | `==`  | Equality         | `"ab" == "ab"` | `TRUE`   |
| `!=`     | `≠`     | `!=`  | Inequality       | `"ab" ≠ "cd"`  | `TRUE`   |
| `<`      | —       | `<`   | Less than        | `"ab" < "ac"`  | `TRUE`   |
| `<=`     | `≤`     | `<=`  | Less or equal    | `"ab" ≤ "ab"`  | `TRUE`   |
| `>`      | —       | `>`   | Greater than     | `"ac" > "ab"`  | `TRUE`   |
| `>=`     | `≥`     | `>=`  | Greater or equal | `"ab" ≥ "ab"`  | `TRUE`   |

**Future operators**:

- `∈` (element-of): substring membership
- `∋` (contains): substring membership (reversed)

## Operator Precedence

String operators fit into overall operator precedence:

1. Concatenation: `++` (same level as arithmetic operators)
2. Comparison: `<`, `≤`, `>`, `≥`, `==`, `≠` (lower than concatenation)

**No precedence between `++` and arithmetic** - use parentheses:

```stone
# Error: ambiguous
"x" ++ "y" + "z"            # Error: mixing ++ and +

# Explicit grouping
"x" ++ ("y" + "z")          # If + is overloaded for strings elsewhere
```

**Comparison has lower precedence**:

```stone
# OK: comparison after concatenation
"ab" ++ "cd" == "abcd"      # ("ab" ++ "cd") == "abcd"  →  TRUE
"x" ++ "y" < "z"            # ("x" ++ "y") < "z"
```

## Grammar

```ruby
# In grammar
rule(:expr) { 
  comparison_expr 
}

rule(:comparison_expr) { 
  concat_expr + (ws! + comparison_op + ws! + concat_expr).maybe 
}

rule(:comparison_op) { 
  terminal { /<=|≤|>=|≥|<|>|==|≠|!=/ }
}

rule(:concat_expr) {
  primary_expr + (ws! + concat_op + ws! + primary_expr).zero_or_more
}

rule(:concat_op) {
  terminal { /\+\+/ }
}

rule(:primary_expr) {
  # Strings, identifiers, function calls, parenthesized expressions, etc.
}
```

## Implementation Strategy

### Phase 1: Core Operators

1. String concatenation (`++`)
2. String equality (`==`, `!=`/`≠`)

### Phase 2: Comparison

1. Lexicographic comparison (`<`, `≤`, `>`, `≥`)

### Phase 3: Methods

1. `contains?(substring)` method
2. `includes?(substring)` alias

### Phase 4: Future Operators

1. Element-of operator (`∈`)
2. Contains operator (`∋`)

## Test Cases

```ruby
RSpec.describe "String Operators" do
  describe "concatenation (++)" do
    it "concatenates two strings"
    it "concatenates empty strings"
    it "chains multiple concatenations"
    it "is associative in result"
    it "handles UTF-8 strings"
    it "empty string is identity element"
  end

  describe "equality (==)" do
    it "compares equal strings"
    it "compares unequal strings"
    it "is case-sensitive"
    it "works with empty strings"
    it "is reflexive, symmetric, transitive"
  end

  describe "inequality (!=, ≠)" do
    it "returns FALSE for equal strings"
    it "returns TRUE for unequal strings"
    it "accepts both != and ≠ symbols"
  end

  describe "lexicographic comparison (<, ≤, >, ≥)" do
    it "< compares alphabetically (ASCII)"
    it "<= includes equality"
    it "> compares in reverse"
    it ">= includes equality"
    it "shorter string comes first as prefix"
    it "empty string is smallest"
    it "accepts Unicode symbols (≤, ≥)"
  end

  describe "operator precedence" do
    it "comparison after concatenation"
    it "++ groups left-to-right"
  end

  describe "contains? method" do
    it "returns TRUE when substring present"
    it "returns FALSE when substring absent"
    it "empty string always contained"
    it "works with overlapping substrings"
  end

  describe "includes? method" do
    it "is alias for contains?"
  end

  describe "UTF-8 handling" do
    it "concatenates multi-byte characters correctly"
    it "compares multi-byte characters correctly"
    it "empty string works with UTF-8"
  end
end
```

## Acceptance Criteria

- [ ] String concatenation (`++`) works correctly
- [ ] String equality (`==`, `!=`, `≠`) works correctly
- [ ] Lexicographic comparison (`<`, `≤`, `>`, `≥`) works correctly
- [ ] Unicode comparison symbols (≤, ≥, ≠) are supported
- [ ] All operators handle empty strings correctly
- [ ] All operators handle UTF-8 strings correctly (byte-level for now)
- [ ] Operator precedence is correct (comparison < concatenation)
- [ ] Performance is acceptable (use memcpy/memcmp)
- [ ] `contains?` and `includes?` methods work correctly
- [ ] Comprehensive tests cover edge cases
- [ ] `make test` passes
- [ ] `make lint` passes

## Future Work

- [ ] Element-of operator (`∈`) for substring membership
- [ ] Contains operator (`∋`) for substring membership
- [ ] Locale-aware string comparison (collation)
- [ ] Unicode normalization for comparisons
- [ ] Case-insensitive comparison operators or methods
- [ ] Pattern matching operator (`=~`) with regex
- [ ] String interpolation operator/syntax (beyond `.interp()` method)
- [ ] Subscript operator (`[]`) for indexing and slicing
- [ ] Operator overloading for user-defined types
