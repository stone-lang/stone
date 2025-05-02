# Thoughts

These are various ideas I've had about what
an ideal programming language would look like.

## Unique combination of ideas

- No keywords
    - Or minimal, if necessary
- All definitions begin with the identifier on the left
    - No keywords for definitions
    - Functions, classes, methods, etc are just constants
    - Improved readability and visibility
- Importing is just compile-time definition
- Compiled, but no AOT/JIT distinction
    - Compiler figures out when it can execute each statement/block
        - Compile time
        - Initialization time
        - Run time
- Blocks as primary meta-programming construct
- Eager evaluation by default
    - Blocks are used to defer evaluation
- Default to 1-based indexing
    - So first, rest, last, nth make sense
    - But also allow 0-based
    - Might allow indexing by *any* Ordinal
        - `List[Any, 0..]`
        - `List[Any, 1..]`
- Encapsulation like in OOP
    - But objects are immutable
        - Use actors if you need mutability
- Actors
- Nominal typing by default, aliases allowed
