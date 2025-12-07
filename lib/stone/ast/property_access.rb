require "stone/ast"


module Stone
  class AST
    class PropertyAccess < Stone::AST

      attr_reader :receiver, :property

      def initialize(receiver, property)
        @receiver = receiver
        @property = property
        @name = :property_access
      end

      def to_llir(builder, mod)
        # Special handling for String.byte_count
        # We need access to the AST node to get byte count at compile time
        if @property == "byte_count"
          string_literal = get_string_literal(mod)
          return LLVM::Int64.from_i(string_literal.bytesize) if string_literal
        end

        receiver_value = @receiver.to_llir(builder, mod)
        receiver_type = infer_type(@receiver, mod)

        implementation = Stone::PropertyRegistry.lookup(receiver_type, @property)
        fail "Property '#{@property}' not found for type '#{receiver_type}'" unless implementation

        implementation.call(builder, receiver_value)
      end

      private def get_string_literal(mod)
        # If receiver is a StringLiteral, return it directly
        return @receiver if @receiver.is_a?(StringLiteral)

        # If receiver is a Reference to a string constant, look it up
        return mod.string_constants[@receiver.identifier] if @receiver.is_a?(Reference)

        nil
      end

      private def infer_type(node, mod)
        result = infer_type_from_node(node, mod)
        fail "Could not infer type for #{node.class} #{node.is_a?(Reference) ? node.identifier : ''}" unless result

        result
      end

      private def infer_type_from_node(node, mod)
        case node
        when IntegerLiteral then "Int"
        when BooleanLiteral then "Bool"
        when StringLiteral then "String"
        when Reference then node.type(mod)
        when PropertyAccess then infer_property_access_type(node, mod)
        else
          fail "Cannot infer type of #{node.class}"
        end
      end

      private def infer_property_access_type(node, mod)
        # For PropertyAccess, we need to know what type the PROPERTY returns, not the receiver
        receiver_type = infer_type(node.receiver, mod)
        property_return_type(receiver_type, node.property)
      end

      private def property_return_type(receiver_type, property_name)
        # Map of which properties return which types
        property_types = {
          "Bool" => {"not" => "Bool"},
          "Int" => {"positive?" => "Bool", "negative?" => "Bool", "zero?" => "Bool"},
          "String" => {"byte_count" => "Int"}
        }
        property_types.dig(receiver_type, property_name)
      end

    end
  end
end
