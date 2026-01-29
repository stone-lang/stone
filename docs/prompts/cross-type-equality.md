# Cross-Type Equality Coercion

## Overview

Allow equality comparison between values of different but related types,
returning TRUE when the values are semantically equivalent.
Currently, cross-type comparisons always return FALSE.

## Prerequisites

- Universal equality operators (`==`, `!=`, `≠`, `equals?`)
- RTTI-based type dispatch for equality
- Numeric types beyond Int (Float, Decimal, etc.)

## Goals

1. `1.0 == 1` returns TRUE (numeric coercion)
2. Define which type pairs support cross-type equality
3. Maintain symmetry: `a == b` must equal `b == a`
4. Maintain transitivity where possible

## Design Decisions

### Which Types Can Be Cross-Compared?

Numeric types should be comparable across representations:

```stone
1 == 1.0        # TRUE - Int vs Float
1.0 == 1        # TRUE - symmetric
2 == 2.0        # TRUE
1 == 1.5        # FALSE - not the same value
```

Non-numeric types should NOT be cross-comparable:

```stone
1 == "1"        # FALSE - Int vs String (no coercion)
TRUE == 1       # FALSE - Bool vs Int (no coercion)
```

### Coercion Direction

When comparing two numeric types, promote the less precise type
to the more precise type, then compare:

- Int vs Float: promote Int to Float, compare as Float
- Int vs Decimal: promote Int to Decimal, compare as Decimal
- Float vs Decimal: promote Float to Decimal, compare as Decimal

### Symmetry Requirement

Cross-type equality MUST be symmetric. If `a == b` is TRUE,
then `b == a` must also be TRUE. This is enforced by always
promoting to the same target type regardless of argument order.

### Hashing Consistency

If `a == b` is TRUE, then `hash(a)` must equal `hash(b)`.
This means `hash(1)` must equal `hash(1.0)`.
Implementation must ensure hash functions are consistent
across coercible types.

## Implementation Considerations

### RTTI Dispatch Changes

The current equality dispatch returns FALSE for different type tags.
Cross-type equality requires a coercion lookup when tags differ:

1. Compare type tags -- if same, dispatch as usual
2. If different, check if the type pair supports coercion
3. If coercible, promote and compare
4. If not coercible, return FALSE

### Coercion Table

A static table mapping type pairs to coercion functions:

```text
(Int, Float)    -> promote_int_to_float, then compare
(Int, Decimal)  -> promote_int_to_decimal, then compare
(Float, Decimal) -> promote_float_to_decimal, then compare
```

The table should be symmetric (lookup works in either order).

## Acceptance Criteria

- [ ] `1 == 1.0` returns TRUE (requires Float type)
- [ ] `1.0 == 1` returns TRUE (symmetric)
- [ ] `1 == 1.5` returns FALSE
- [ ] `1 == "1"` returns FALSE (no string coercion)
- [ ] `TRUE == 1` returns FALSE (no bool coercion)
- [ ] Hash consistency: `hash(1) == hash(1.0)`
- [ ] All existing tests pass

## Notes

- This feature is blocked on implementing Float/Decimal types
- Start with Int vs Float coercion as the first case
- Consider whether user-defined types can opt into cross-type equality
