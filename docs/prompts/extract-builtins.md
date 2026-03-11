# Prompt: Extract Builtin Functions to Separate File

## Context

The Stone programming language currently defines all builtin functions inline in `lib/stone/ast/program_unit.rb`. As the number of builtins grows, this file is becoming harder to maintain. The builtin functions should be extracted to a separate module.

## Current State

In `lib/stone/ast/program_unit.rb`, the following methods define builtin functions:

- `setup_builtin_functions(mod)` - Entry point that calls individual function definers
- `define_sum_function(mod)` - Arithmetic: addition with overflow checking
- `define_comparison_operators(mod)` - Dispatches to individual comparison definers
- `define_eq_function(mod)` - Comparison: `==`
- `define_ne_function(mod)` - Comparison: `!=` and `≠`
- `define_lt_function(mod)` - Comparison: `<`
- `define_le_function(mod)` - Comparison: `<=` and `≤`
- `define_gt_function(mod)` - Comparison: `>`
- `define_ge_function(mod)` - Comparison: `>=` and `≥`
- `build_icmp_body(func, predicate)` - Helper for comparison functions
- `build_sum_body(func, mod)` - Helper for sum function
- `sadd_with_overflow_intrinsic(mod)` - LLVM intrinsic for overflow-checked addition

## Requirements

1. Create a new file `lib/stone/builtins.rb` with a `Stone::Builtins` module
2. Move all builtin function definitions to this new module
3. The module should provide a single public method: `Builtins.register_all(mod)` that takes an LLVM module
4. Keep helper methods private within the module
5. Update `program_unit.rb` to use the new module
6. Ensure all existing tests continue to pass
7. Follow the project's coding style (see AGENTS.md)

## Suggested Structure

```ruby
# lib/stone/builtins.rb
module Stone
  module Builtins
    module_function

    def register_all(mod)
      register_arithmetic(mod)
      register_comparison(mod)
    end

    private

    def register_arithmetic(mod)
      # sum function
    end

    def register_comparison(mod)
      # ==, !=, <, <=, >, >=, and Unicode variants
    end

    # ... helper methods
  end
end
```

## Acceptance Criteria

- [ ] All builtin function code moved to `lib/stone/builtins.rb`
- [ ] `program_unit.rb` uses `Stone::Builtins.register_all(mod)`
- [ ] All 218+ tests pass
- [ ] Linting passes (`make lint`)
- [ ] Code follows existing patterns and style
- [ ] No new public methods exposed beyond `register_all`

## Notes

- The LLVM module (`mod`) must be passed to each function that needs it
- Consider grouping related functions (arithmetic, comparison, etc.)
- Future builtins might include: subtraction, multiplication, division, modulo, logical operators (and, or, not)
- This is a pure refactoring task - no new functionality should be added
