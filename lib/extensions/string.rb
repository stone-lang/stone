# TODO: Get these added to the `pretty_ruby` gem, and use that. (Note that it uses refinements, not monkey-patching.)

class String

  # Allow Scheme-style `first`.
  def first(count = 1)
    self[0..(count - 1)]
  end

  # Allow Scheme-style `rest`.
  def rest(count = 1)
    drop(count)
  end

  def drop(count = 1)
    self.chars.drop(count).join
  end

  # Allow Scheme-style `tail`.
  def tail
    return self if size.zero?
    last(size - 1)
  end

  def last(count = 1)
    self.chars.last(count).join
  end

end
