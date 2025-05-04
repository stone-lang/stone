Hypotheses
==========

- Programmers will be OK without explicit loops.
    - Using `map`, `find`, etc will cover 99.99% of cases.
    - See "Regularized Programming with the Bosque Language".
- Including another package should list the expected package version.
    - Example: `xyz := import('XYZ', ">= 3.9 < 4.0")`
    - Dependency management will read all the import statements to resolve actual versions used.
        - The resolved versions will be stored in `config/stone.dependencies`.
            - TODO: I'm not really happy with that file name.
- Exporting the first definition in a file will be easy to understand.
- Definitions in a file should be in order of importance.
    - The file should tell a story, top-down.
    - Corollary: Imports should come last, not first.
    - Corollary: Definition order should not matter to the compiler.
- Type signatures of libraries/packages should be easily read.
    - Maybe store them in the object file?
    - Maybe the IDE can just hide all source other than the type signatures.



