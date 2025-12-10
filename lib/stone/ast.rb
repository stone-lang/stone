module Stone
  class AST

    attr_reader :name, :children

    def initialize(name, children = nil)
      @name = name
      @children = children
    end

    # Helper module for checking if a node represents a record instance
    module RecordHelpers

    module_function

      # Check if a node is a Reference to a record instance
      def record_instance_node?(node, mod)
        node.is_a?(Stone::AST::Reference) && mod.record_instance?(node.identifier)
      end

    end

  end
end
