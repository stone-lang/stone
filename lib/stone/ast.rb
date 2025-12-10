module Stone
  class AST

    attr_reader :name, :children

    def initialize(name, children = nil)
      @name = name
      @children = children
    end

    def type(_context = nil)
      fail NotImplementedError, "#{self.class} must implement #type"
    end

  end
end
