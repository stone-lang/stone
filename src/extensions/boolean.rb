class TrueClass

  def ∧(other)
    !!other
  end

  def ∨(_other)
    true
  end

end


class FalseClass

  def ∧(_other)
    false
  end

  def ∨(other)
    !!other
  end

end
