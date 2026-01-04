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
        return_type = receiver_type.property_return_type(@property)
        fail Stone::PropertyError, "Property '#{@property}' not found for type '#{receiver_type.name}'" unless return_type

        return_type
      end

      def to_llir(builder, mod)
        # 1. Check if this is a record field access (highest priority)
        return access_record_field(builder, mod) if record_field_access?(mod)

        # Infer the receiver type for subsequent checks
        receiver_type = infer_type(@receiver, mod)

        # Try different property access strategies
        handle_type_as_string(builder, mod, receiver_type) ||
          handle_byte_count(mod) ||
          handle_computed_property(builder, mod, receiver_type) ||
          fail_property_not_found(receiver_type)
      end

      private def handle_type_as_string(builder, mod, receiver_type)
        return nil unless @property == "as_String" && receiver_type == "Type"

        generate_type_name_string(builder, mod)
      end

      private def handle_byte_count(mod)
        return nil unless @property == "byte_count"

        string_literal = get_string_literal(mod)
        LLVM::Int64.from_i(string_literal.bytesize) if string_literal
      end

      private def handle_computed_property(builder, mod, receiver_type)
        function_name = "#{receiver_type}@#{@property}"
        computed_func = mod.lookup_function(function_name)
        return nil unless computed_func

        receiver_value = @receiver.to_llir(builder, mod)
        builder.call(computed_func, receiver_value, "#{@property}_result")
      end

      private def fail_property_not_found(receiver_type)
        fail Stone::PropertyError, "Property '#{@property}' not found for type '#{receiver_type}'"
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

        # Try simple literal type check first
        simple_type = simple_literal_type(inner)
        return simple_type if simple_type

        # Try special case handling
        complex_type = complex_expression_type(inner, mod)
        return complex_type if complex_type

        # Fallback to TypeContext for complex cases
        type_via_context(inner, mod) || "Unknown"
      end

      private def simple_literal_type(inner)
        case inner
        when IntegerLiteral then "Int"
        when BooleanLiteral then "Bool"
        when StringLiteral then "String"
        when TypeOfExpression then "Type"
        when TypeReference then "Type"
        end
      end

      private def complex_expression_type(inner, mod)
        case inner
        when FunctionCall then function_call_result_type(inner)
        when PropertyAccess then infer_property_access_type(inner, mod)
        end
      end

      private def function_call_result_type(inner)
        inner.function_name.match?(/^(==|!=|≠|<|<=|≤|>|>=|≥)$/) ? "Bool" : "Unknown"
      end

      private def type_via_context(inner, mod)
        context = Stone::TypeContext.new(mod)
        inner_type = inner.type(context)
        type_class_to_name(inner_type) if inner_type
      rescue Stone::TypeError
        nil
      end

      private def type_class_to_name(type_obj)
        return type_obj.name if type_obj.is_a?(Stone::Type)

        "Unknown"
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
        literal_node_type(node) || complex_node_type(node, mod) || fail_cannot_infer_type(node)
      end

      private def literal_node_type(node)
        case node
        when IntegerLiteral then "Int"
        when BooleanLiteral then "Bool"
        when StringLiteral then "String"
        when TypeOfExpression then "Type"
        when TypeReference then "Type"
        end
      end

      private def complex_node_type(node, mod)
        case node
        when Reference then node.type(mod)
        when PropertyAccess then infer_property_access_type(node, mod)
        when FunctionCall then infer_function_call_type(node, mod)
        else
          fail "Cannot infer type of #{node.class}"
        end
      end

      private def fail_cannot_infer_type(node)
        fail "Cannot infer type of #{node.class}"
      end

      private def infer_property_access_type(node, mod)
        # For PropertyAccess, we need to know what type the PROPERTY returns, not the receiver
        receiver_type = infer_type(node.receiver, mod)
        property_return_type(receiver_type, node.property)
      end

      private def property_return_type(receiver_type, property_name)
        # Map of which properties return which types
        property_types = {
          "Bool" => {"not" => "Bool", "as_String" => "String"},
          "Int" => {"positive?" => "Bool", "negative?" => "Bool", "zero?" => "Bool", "as_String" => "String"},
          "String" => {"byte_count" => "Int", "empty?" => "Bool", "as_String" => "String"},
          "Type" => {"as_String" => "String"}
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
