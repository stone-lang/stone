# TODO: Get these added to the `pretty_ruby` gem, and use that. (Note that it uses refinements, not monkey-patching.)

module Enumerable

  # Allow Scheme-style `rest`.
  def rest(count = 1)
    self.drop(count)
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

  def map_dig(*args)
    map{ |a| a.dig(*args) }
  end

end
