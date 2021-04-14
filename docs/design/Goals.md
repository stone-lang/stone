Goals
=====

These are my goals for Stone, roughly in order of importance.
My goals for Stone are varied, and perhaps not typical for a programming language.

* Have fun
    * Have fun designing and implementing a new language
    * Make programming more fun for others
        * Similar to Ruby's focus on joy
* See if I can make something useful
    * Useful to myself, and hopefully others
    * Explore some ideas I have
        * Can we merge Ruby's ideas with static types, immutability, and AOT compilation?
        * Can we merge pure FP and OOP nicely?
            * In a way that OOP programmers will be willing and able to move to?
        * Can we make a "regular" syntax that's still familiar?
    * Focus on practical aspects, over cutting-edge academic topics
* General-purpose
    * Good at web apps, CLI utilities, GUI apps, one-off "scripts"
    * Good for math, engineering, text processing, web services, network access
* High-level
    * Don't optimize for low-level use
        * No operators for bit operations
    * Don't require manual memory management
    * In general, make the computer do more work
* Correctness is more important than speed
    * Floating-point binary math is not the default
        * We want `0.1 + 0.2 == 0.3` to be TRUE, as almost everyone would expect
    * Arbitrary-precision math
* Make something easier to learn than Ruby and Python
    * More "regularity"
    * Fewer concepts to learn
* Faster than Ruby and Python
    * Faster than their mainline implementations
    * Not counting compile time - that can be amortized
        * With modern IDEs, it can start as soon as a change is made
            * Can use caching, so only changes to files are compiled

Stretch Goals
-------------

* See if I can construct a language with no keywords or special forms
* See if I can construct a language with a minimal number of built-in functions
