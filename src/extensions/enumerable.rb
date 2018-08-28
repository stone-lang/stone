# TODO: Get these added to the `pretty_ruby` gem, and use that. (Note that it uses refinements, not monkey-patching.)

module Enumerable

  def rest
    self.drop(1)
  end

  def map_dig(*args)
    map{ |a| a.dig(*args) }
  end

end
