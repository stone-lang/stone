# TODO

## Union Type Runtime Dispatch

The following tests in `spec/language/types/union_type_spec.rb` are pending because they require **runtime type dispatch** - the ability to check the type tag at runtime and branch accordingly.

### Pending Tests

1. **NULL detection** (`allows nullable field with NULL value`, `allows Bool | Null field with NULL value`)
   - Problem: NULL payload is 0, indistinguishable from Int(0) without checking type tag
   - Solution: Check type tag against `@Stone.Type.Null` constant before returning payload

2. **Bool conversion** (`allows Bool | Null field with Bool value`)
   - Problem: Bool is stored as i64 (0 or 1), but Ruby expects `true`/`false`
   - Solution: Check type tag, truncate i64 to i1 if type is Bool

3. **String conversion** (`allows Int | String field with String value`)
   - Problem: String pointer stored as i64, but Ruby needs to read string from pointer
   - Solution: Check type tag, convert i64 back to pointer if type is String

4. **Chained record access** (`allows recursive type with NULL terminator`, `allows Record field with union type`, `allows union of record types`)
   - Problem: Union payload containing record pointer (as i64) can't be accessed as record
   - Solution: Pattern matching or type-aware property access that converts payload back to pointer

### Implementation Approach

The cleanest solution is **pattern matching** on union types:

```stone
match b.value {
  case x :: Int { sum(x, 1) }
  case NULL { 0 }
}
```

This would:

1. Extract the type tag from the union struct
2. Compare against each case's type constant
3. Extract and cast payload appropriately for each branch

### Alternative: Runtime Type Checking in Property Access

For simpler cases, property access could check the type tag and:

- Return null pointer if type is Null
- Truncate to i1 if type is Bool
- Convert i64 to pointer if type is String or Record

This requires knowing the expected return type at compile time, which may not always be possible.
