Object-Oriented Programming
===========================

I believe that FP aficionados threw out the baby with the bath water in abandoning the ideas of Object-Oriented Programming.
I think it's mutability that was the problem, not OOP.
I think that we can take Gary Bernhardt's ideals from his _Boundaries_ talk,
keeping an FP core with an OOP shell.
I think we do that by making everything immutable, except for actors.
But we can still have immutable objects that have types that vary at runtime,
with polymorphism based on the type.

Classes
-------

* `Class` is a function that returns a function that returns instances of the newly created class
    * So Class is a subclass of Function.

