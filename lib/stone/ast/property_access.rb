require "stone/ast"
require "stone/error/property_error"


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
        # Check if this is a record field access
        return access_record_field(builder, mod) if record_field_access?(mod)

        # Special handling for String.byte_count
        # We need access to the AST node to get byte count at compile time
        if @property == "byte_count"
          string_literal = get_string_literal(mod)
          return LLVM::Int64.from_i(string_literal.bytesize) if string_literal
        end

        receiver_value = @receiver.to_llir(builder, mod)
        receiver_type = infer_type(@receiver, mod)

        implementation = Stone::PropertyRegistry.lookup(receiver_type, @property)
        fail Stone::PropertyError, "Property '#{@property}' not found for type '#{receiver_type}'" unless implementation

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
        when FunctionCall then infer_function_call_type(node, mod)
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

      private def infer_function_call_type(node, mod)
        # If the function call is a record constructor, return the record type
        return node.function_name if mod.record_type?(node.function_name)

        # Otherwise, we can't infer the type yet (would need return type annotations)
        nil
      end

      private def record_field_access?(mod)
        # Check if receiver is a Reference to a record instance
        return Stone::AST::RecordHelpers.record_instance_node?(@receiver, mod) if @receiver.is_a?(Reference)

        # Check if receiver is a FunctionCall that returns a record
        return mod.record_type?(@receiver.function_name) if @receiver.is_a?(FunctionCall)

        false
      end

      private def access_record_field(builder, mod)
        record_type_name = get_record_type_name(mod)
        record_def = lookup_record_definition(mod, record_type_name)
        field_index = get_field_index(record_def, record_type_name)

        # Evaluate the receiver to get the record struct
        receiver_value = @receiver.to_llir(builder, mod)

        # Extract the field value from the struct
        builder.extract_value(receiver_value, field_index, "#{@property}_value")
      end

      def returns_string_field?(mod)
        return false unless record_field_access?(mod)

        record_type_name = get_record_type_name(mod)
        record_def = mod.record_types[record_type_name]
        return false unless record_def

        field_def = record_def.fields.find { |f| f[:name] == @property }
        field_def && field_def[:type] == "String"
      end

      private def get_record_type_name(mod)
        if @receiver.is_a?(Reference)
          mod.record_instance_type(@receiver.identifier)
        elsif @receiver.is_a?(FunctionCall)
          @receiver.function_name
        end
      end

      private def lookup_record_definition(mod, record_type_name)
        record_def = mod.record_types[record_type_name]
        fail "Unknown record type: #{record_type_name}" unless record_def

        record_def
      end

      private def get_field_index(record_def, record_type_name)
        field_index = record_def.field_index(@property)
        fail Stone::PropertyError, "Property '#{@property}' not found for record type '#{record_type_name}'" unless field_index

        field_index
      end

    end
  end
end
