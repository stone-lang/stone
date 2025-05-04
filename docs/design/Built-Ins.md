Built-Ins
=========

* I'd like to minimize the number of built-in functions as much as possible
    * This will **require** that we have good inter-operability with C code
        * We'll need to specify the argument and return types
        * We'll likely need low-level data types
            * C.Byte
            * C.Int64
            * C.ByteArray
            * C.String
        * This could be done by having a `__BUILTIN_IMPORT_FROM_C__` function
    * Because we'd want **most** of the standard library to be written in Stone
        * But there will be many places where we will **have to** interface with C libraries
    * Likely require built-ins:
        * `__BUILTIN_IMPORT__`
        * `__BUILTIN_IMPORT_FROM_C__`
        * `__BUILTIN_TYPE__`
            * Gets the (dynamic) type of the argument that's passed in
