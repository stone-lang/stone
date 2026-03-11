# Fix: `if(TRUE, ..., ...)` Incorrectly Takes Else Branch

## Problem Statement

The `if` built-in function in Stone has a bug where using the TRUE literal as the condition causes it to take the else branch instead of the then branch:

```stone
if(TRUE, { 42 }, { 0 })   # Returns 0 (WRONG - should return 42)
if(FALSE, { 0 }, { 42 })  # Returns 42 (CORRECT)
if(==(5, 5), { 42 }, { 0 }) # Returns 42 (CORRECT - comparison returns true)
```

## Background

The `if` function was just implemented as a built-in function with the following signature:

- Parameters: `(i1 condition, function_ptr then_block, function_ptr else_block)`
- Returns: `i64`
- Implementation: Uses LLVM conditional branch (`builder.cond`) to select between basic blocks, calls the appropriate block function pointer, and uses a phi node to merge results

The implementation is in `/Users/craigbuchek/Work/stone/lib/stone/ast/program_unit.rb` in the `define_if_function` and `build_if_body` methods.

## What Works

1. **Blocks work correctly**: `{ 42 }` syntax creates 0-parameter lambda functions that can be called
2. **Comparisons work**: When using comparison operators like `==(5, 5)` that return i1 values, the if function works correctly
3. **FALSE literal works**: `if(FALSE, ..., ...)` correctly takes the else branch
4. **LLVM IR logic is sound**: The conditional branching, phi nodes, and function pointer calling all work

## What's Broken

When the TRUE literal is used as the condition, the conditional branch takes the wrong path. Since:

- `if(FALSE, ..., ...)` works correctly
- `if(comparison_returning_true, ..., ...)` works correctly
- `if(TRUE, ..., ...)` takes the else branch (wrong)

This suggests the issue is specifically with how the TRUE literal value is represented or passed as a function parameter.

## Relevant Code Locations

1. **TRUE/FALSE literal definition**: `/Users/craigbuchek/Work/stone/lib/stone/type/Bool.rb`

   - `TRUE = 1` and `FALSE = 0`

2. **Boolean literal AST**: `/Users/craigbuchek/Work/stone/lib/stone/ast/boolean_literal.rb`
   - `to_llir` method returns `LLVM::Int1.from_i(@value)` where `@value` is 1 for TRUE or 0 for FALSE

3. **if function implementation**: `/Users/craigbuchek/Work/stone/lib/stone/ast/program_unit.rb`
   - `define_if_function(mod)` creates function with signature `[i1, block_ptr, block_ptr] -> i64`
   - `build_if_body(func)` uses `func.params[0]` as condition for `builder.cond(condition, then_bb, else_bb)`

4. **Comparison operators**: `/Users/craigbuchek/Work/stone/lib/stone/ast/program_unit.rb`
   - Return i1 values via `builder.icmp(predicate, ...)`
   - These work correctly when used as if conditions

## Test Cases

The test file `/Users/craigbuchek/Work/stone/spec/language/functions/if_function_spec.rb` has:

- ✓ Tests with FALSE literal pass
- ✓ Tests with comparisons pass
- ✗ Tests with TRUE literal fail

Run tests with:

```bash
cd /Users/craigbuchek/Work/stone && mise exec -- bundle exec rspec spec/language/functions/if_function_spec.rb --format documentation
```

## Investigation Questions

1. Is there a difference in how `LLVM::Int1.from_i(1)` creates i1 values versus how `builder.icmp` creates them?
2. When TRUE is passed as a function argument, is it being converted or extended differently than comparison results?
3. Could there be an issue with how `func.params[0]` retrieves the i1 parameter value?
4. Is the TRUE constant value being inverted somewhere (1 treated as false, 0 as true)?

## Task

Debug and fix the issue so that `if(TRUE, { 42 }, { 0 })` returns 42 instead of 0. The fix should:

1. Make all if function tests pass
2. Not break any existing tests for blocks, lambdas, boolean literals, or anything else
3. Maintain the current architecture (don't need to redesign the `if` function)

## Debugging Approach

Consider:

1. Add temporary debug output to see what value `condition` has in `build_if_body`
2. Check if TRUE literal needs to be evaluated differently in function call contexts
3. Compare the LLVM IR generated for TRUE literal vs comparison operators
4. Test if manually creating an i1 constant in the if function fixes it
5. Check if there's a signedness or comparison issue with i1 values

Good luck!
