require "stone/ast/expression"
require "stone/error/property_error"


module Stone
  class AST
    class PropertyAccess < Stone::AST::Expression

      attr_reader :receiver, :property

      def initialize(receiver, property)
        @receiver = receiver
        @property = property
        @name = :property_access
      end

      def type(context = nil)
        receiver_type = @receiver.type(context)
        return nil unless receiver_type

        return_type = receiver_type.property_return_type(@property)
        fail Stone::PropertyError, "Property '#{@property}' not found for type '#{receiver_type.name}'" unless return_type

        return_type
      end

      def to_llir(builder, mod)
        # 1. Check if this is a record field access (highest priority)
        return access_record_field(builder, mod) if record_field_access?(mod)

        # Resolve the receiver type for subsequent checks
        receiver_type = resolve_node_type(@receiver, mod)

        # Try different property access strategies
        handle_type_as_string(builder, mod, receiver_type) ||
          handle_byte_count(mod) ||
          handle_computed_property(builder, mod, receiver_type) ||
          fail_property_not_found(receiver_type)
      end

      private def handle_type_as_string(builder, mod, receiver_type)
        return nil unless @property == "as_String" && receiver_type == Stone::Type::Type

        generate_type_name_string(builder, mod)
      end

      private def handle_byte_count(mod)
        return nil unless @property == "byte_count"

        string_literal = get_string_literal(mod)
        LLVM::Int64.from_i(string_literal.bytesize) if string_literal
      end

      private def handle_computed_property(builder, mod, receiver_type)
        return nil unless receiver_type

        computed_func = lookup_computed_property_function(mod, receiver_type)
        return nil unless computed_func

        receiver_value = @receiver.to_llir(builder, mod)
        builder.call(computed_func, receiver_value, "#{@property}_result")
      end

      private def lookup_computed_property_function(mod, receiver_type)
        mod.lookup_function("#{receiver_type.name}@#{@property}")
      end

      private def fail_property_not_found(receiver_type)
        type_name = receiver_type&.name || "Unknown"
        fail Stone::PropertyError, "Property '#{@property}' not found for type '#{type_name}'"
      end

      private def generate_type_name_string(builder, mod)
        # Determine the actual type name from the receiver
        type_name = determine_type_name_from_receiver(mod)

        # Create a string literal and get its pointer
        string_literal = Stone::AST::StringLiteral.new(type_name)
        string_literal.to_llir(builder, mod)
      end

      private def determine_type_name_from_receiver(mod)
        case @receiver
        when TypeReference
          "Type"
        when TypeOfExpression
          # Determine the type of the inner expression
          determine_type_of_expression_result(@receiver, mod)
        else
          "Unknown"
        end
      end

      private def determine_type_of_expression_result(type_of_expr, mod)
        inner = type_of_expr.inner_expression
        inner_type = resolve_node_type(inner, mod)
        inner_type&.name || "Unknown"
      end

      private def get_string_literal(mod)
        # If receiver is a StringLiteral, return it directly
        return @receiver if @receiver.is_a?(StringLiteral)

        # If receiver is a Reference to a string constant, look it up
        return mod.string_constants[@receiver.identifier] if @receiver.is_a?(Reference)

        nil
      end

      private def resolve_node_type(node, mod)
        Stone::AST::TypeResolver.resolve_node_type(node, mod)
      end

      private def record_field_access?(mod)
        # Check if receiver is a Reference to a record instance
        return Stone::AST::RecordHelpers.record_instance?(@receiver, mod) if @receiver.is_a?(Reference)

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
