class TrueClass

  include Comparable

  def ∧(other)
    !!other
  end

  def ∨(_other)
    true
  end

  def <=>(other)
    return 1 if other.instance_of?(FalseClass)
    return 0 if other.instance_of?(TrueClass)
    fail ArgumentError, "comparison of Boolean with #{other.class} failed"
  end

  def ==(other)
    other.instance_of?(TrueClass)
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
    return -1 if other.instance_of?(TrueClass)
    return 0 if other.instance_of?(FalseClass)
    fail ArgumentError, "comparison of Boolean with #{other.class} failed"
  end

  def ==(other)
    other.instance_of?(FalseClass)
  end

end
