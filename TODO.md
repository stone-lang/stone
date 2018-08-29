TODO
====

- [x] Create GitHub repo
- [x] Create GitHub organization
- [x] Buy domain
- [x] Add a license
- [x] Write a basic README
- [x] Add a TODO list
- [ ] Add a code of conduct
- [ ] Set up GitHub pages
- [ ] Point domain at GitHub pages
- [x] Write first specification
- [x] Automate testing of specifications
    - [ ] Allow testing of more than 1 result per code block
    - [x] Show progress
    - [ ] Allow debugging
- [ ] Add design docs
- [x] Start on parser and grammar
    - [x] Look into various choices for parsing
    - [ ] Handle syntax errors gracefully
        - [ ] Handle specific issues users will likely encounter
            - [ ] No space around operators
- [ ] Run checks before commits
    - [ ] Make sure all specs are passing
    - [ ] RuboCop
- [ ] Compile to LLVM
- [ ] Static type tracking/checking
    - [ ] Complex types
- [ ] Self-hosting compiler (this one is WAY off)


Specifications
--------------

- [ ] Literals
    - [x] Integers
    - [x] Booleans
    - [x] Text strings
    - [ ] Pair
    - [ ] Fixed-point
    - [ ] Rationals
- [ ] Expressions
    - [ ] Parenthetical expressions
    - [ ] Arithmetic operators
        - [x] Addition
        - [x] Subtraction
        - [x] Multiplication
        - [x] Multiple operands
        - [x] Mixing operators (gives an error in most cases)
            - [x] Allowed mixed operators
        - [ ] Division
        - [ ] Unicode operators
    - [ ] Comparison operators
    - [ ] Boolean operators
        - [x] Not
            - [x] Repeated Not (`!!value`)
        - [ ] And
        - [ ] Or
    - [ ] Text operators
- [x] Exceptions
- [ ] Comments
    - [ ] Per-line
    - [ ] Bracketed
    - [ ] Nested
- [ ] Functions
    - [ ] Function definition
    - [ ] Function call
    - [ ] Varargs
- [ ] Classes
    - [ ] Class definition
    - [ ] Class instantiation
    - [ ] Property definition
    - [ ] Property access
    - [ ] Computed property definition
    - [ ] Computed property access
    - [ ] Class method definition
    - [ ] Class method call
    - [ ] Method definition
    - [ ] Method call
    - [ ] Constructor
    - [ ] Destructor
- [ ] Collections
    - [ ] List
    - [ ] Map


Design Docs
-----------

- [ ] Purpose
- [ ] Goals
- [ ] Features
- [ ] Parsing
