# Church Booleans

TRUE = -> (t, f) { t }
FALSE = -> (t, f) { f }
¬ = -> (a) { a[FALSE, TRUE] }  # NOT
∧ = -> (a, b) { a[b, FALSE] }  # AND
∨ = -> (a, b) { a[TRUE, b] }   # OR
⊕ = -> (a, b) { a[¬[b], b] }   # XOR
⟹ = -> (a, b) { a[b, ¬[a]] }  # IMPLIES
⟸ = -> (a, b) { b[a, ¬[b]] }  # IS IMPLIED BY
⟺ = -> (a, b) { ∧[⟹[a, b], ⟸[a, b]] }  # IFF, EQUIVALENT TO; NOTE: I assume this can be simplified.
⟺ = -> (a, b) { ¬[⊕[a, b]] }  # IFF, EQUIVALENT TO
_if = -> (c, t, e) { c[t, e] } # IF THEN ELSE

def assert(condition)
  fail RuntimeError.new("Assertion failed: #{caller.last}") unless condition
end

assert(¬[FALSE] == TRUE)
assert(¬[TRUE] == FALSE)

assert(∧[FALSE, FALSE] == FALSE)
assert(∧[FALSE, TRUE] == FALSE)
assert(∧[TRUE, FALSE] == FALSE)
assert(∧[TRUE, TRUE] == TRUE)

assert(∨[FALSE, FALSE] == FALSE)
assert(∨[FALSE, TRUE] == TRUE)
assert(∨[TRUE, FALSE] == TRUE)
assert(∨[TRUE, TRUE] == TRUE)

assert(⊕[FALSE, FALSE] == FALSE)
assert(⊕[FALSE, TRUE] == TRUE)
assert(⊕[TRUE, FALSE] == TRUE)
assert(⊕[TRUE, TRUE] == FALSE)

assert(⟹[FALSE, FALSE] == TRUE)
assert(⟹[FALSE, TRUE] == TRUE)
assert(⟹[TRUE, FALSE] == FALSE)
assert(⟹[TRUE, TRUE] == TRUE)

assert(⟸[FALSE, FALSE] == TRUE)
assert(⟸[FALSE, TRUE] == FALSE)
assert(⟸[TRUE, FALSE] == TRUE)
assert(⟸[TRUE, TRUE] == TRUE)

assert(⟺[FALSE, FALSE] == TRUE)
assert(⟺[FALSE, TRUE] == FALSE)
assert(⟺[TRUE, FALSE] == FALSE)
assert(⟺[TRUE, TRUE] == TRUE)

assert(_if[FALSE, :t, :e] == :e)
assert(_if[TRUE, :t, :e] == :t)
