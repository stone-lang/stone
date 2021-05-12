# Church Pairs

Pair = -> (f, s) { ->(x) { x[f, s] } }
first = -> (p) { p[->(f, s) { f }] }
second = -> (p) { p[->(f, s) { s }] }
eq = -> (a, b) { first[a] == first[b] && second[a] == second[b] }

def assert(condition)
  fail RuntimeError.new("Assertion failed: #{caller.last}") unless condition
end

ab = Pair["a", "b"]
assert(first[ab] == "a")
assert(second[ab] == "b")

assert(eq[Pair[:a, :b], Pair[:a, :b]])

puts first[ab]
puts first[ab]
