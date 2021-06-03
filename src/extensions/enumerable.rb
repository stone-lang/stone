# TODO: Get these added to the `pretty_ruby` gem, and use that. (Note that it uses refinements, not monkey-patching.)

module Enumerable

  # Allow Scheme-style `rest`.
  def rest(count = 1)
    drop(count)
  end

  # Allow Scheme-style `tail`.
  def tail
    return self if size.zero?
    last(size - 1)
  end

  # Returns `true` iff all the elements are equal. Returns `false` if there are no elements.
  def same?
    uniq.size == 1
  end

  # Like `first` or `last`, but *requires* that there be exactly one element.
  def only
    fail IndexError, "expected to have exactly 1 element" unless size == 1
    first
  end

  # Allow Rails-style `second`.
  def second
    self[1]
  end

  # Prefer 1-based indexing to get the `nth` element.
  def nth(n) # rubocop:disable Naming/MethodParameterName
    self[n - 1]
  end

  def map_dig(*args)
    map{ |a| a.dig(*args) }
  end

end
