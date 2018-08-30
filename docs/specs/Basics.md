Basics
======

Comments
--------

Comments begin with a `#` character and continue to the end of the line.

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

Or you can use C-style comments:

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
