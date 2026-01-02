module Stone
  class AST

    attr_reader :name, :children

    def initialize(name, children = nil)
      @name = name
      @children = children
    end

    # Helper module for checking if a node represents a record instance
    module RecordHelpers
      # Check if a node is a Reference to a record instance
      module_function def record_instance?(node, mod)
        node.is_a?(Stone::AST::Reference) && mod.record_instance?(node.identifier)
      end

    end

  end
end
