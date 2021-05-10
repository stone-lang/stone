Prelude
=======

The prelude is a file that is implicitly loaded before every file is compiled.
It defines all the "pre-defined" constants - functions, classes, etc.

A custom prelude can be used to change the set of pre-defined constants.
You'll often want to do that for classes and functions that you use in *most*
of the source files within a project.

To test the prelude, we've included a custom prelude by setting the `STONE_PRELUDE`
environment variable.

~~~ stone
CUSTOM_PRELUDE_HAS_BEEN_RUN
#= Boolean(Boolean.TRUE)
~~~
