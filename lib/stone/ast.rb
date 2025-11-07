module Stone
  class AST

    attr_reader :name, :children

    def initialize(name, children = nil)
      @name = name
      @children = children
    end

  end
end
