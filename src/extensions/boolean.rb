class TrueClass

  include Comparable

  def ∧(other)
    !!other
  end

  def ∨(_other)
    true
  end

  def <=>(other)
    return 1 if other.class == FalseClass
    return 0 if other.class == TrueClass
    fail ArgumentError, "comparison of Boolean with #{other.class} failed"
  end

  def ==(other)
    other.class == TrueClass
  end

end


class FalseClass

  include Comparable

  def ∧(_other)
    false
  end

  def ∨(other)
    !!other
  end

  def <=>(other)
    return -1 if other.class == TrueClass
    return 0 if other.class == FalseClass
    fail ArgumentError, "comparison of Boolean with #{other.class} failed"
  end

  def ==(other)
    other.class == FalseClass
  end

end
