Basics
======


Comments
--------

Comments are available in 2 varieties.
Perl-style comments begin with a `#` and continue to the end of the line.

~~~ stone
123 # This is a comment.
#= Number.Integer(123)
~~~

~~~ stone
# This is a comment.
123
#= Number.Integer(123)
~~~

~~~ stone
# This is a comment.
123
# This is another comment.
#= Number.Integer(123)
~~~

C-style block comments start with `/*` and end with `*/`.
Note that C-style comments cannot be nested;
the first `*/` will always end the comment and return to processing code.

~~~ stone
123 /* This is a comment. */
#= Number.Integer(123)
~~~

~~~ stone
1 /* This is a comment. */ + 2
#= Number.Integer(3)
~~~

~~~ stone
123 /* This is a
       multi-line
       comment.
     */
#= Number.Integer(123)
~~~
