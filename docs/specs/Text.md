Text
====

Stone can represent text (what most languages call "strings").

~~~ stone
s := "stressed"
s.reversed
#= Text("desserts")

e := ""
e.empty?
#= Boolean(Boolean.TRUE)

nope := "nope"
nope.empty?
#= Boolean(Boolean.FALSE)

address := "#10 Downing Street"
address.length
#= Number.Integer(18)

lower := "this is all lower case"
lower.upper_cased
#= Text("THIS IS ALL LOWER CASE")

upper := "THIS IS ALL UPPER CASE"
upper.lower_cased
#= Text("this is all upper case")

strip := "  stripped     "
strip.strip
#= Text("stripped")
# NOTE: We need `escape()` working to test chomp (removing trailing \r and \n).
~~~

TODO: escape, interpolate, html_entities
