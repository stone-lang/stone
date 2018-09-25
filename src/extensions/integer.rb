class Integer

  def sign
    ["-", "", "+"][(self <=> 0) + 1]
  end

end
