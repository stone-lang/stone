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

    # Shared type resolution logic for AST nodes
    module TypeResolver
      module_function def resolve_node_type(node, mod)
        case node
        when Stone::AST::Reference then node.type(mod)
        when Stone::AST::FunctionCall then node.type(mod)
        when Stone::AST::PropertyAccess then resolve_property_type(node, mod)
        else node.type
        end
      end

      module_function def resolve_property_type(node, mod)
        receiver_type = resolve_node_type(node.receiver, mod)
        return nil unless receiver_type

        receiver_type.property_return_type(node.property)
      end
    end

  end
end
