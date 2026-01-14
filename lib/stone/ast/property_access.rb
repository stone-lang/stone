require "stone/ast/expression"
require "stone/error/property_error"
require "stone/rtti"


module Stone
  class AST
    class PropertyAccess < Stone::AST::Expression

      TYPE_PROPERTIES = %w[as_String record? primitive? kind size fields].freeze
      FIELD_LIST_PROPERTIES = %w[first name type rest].freeze

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

      def to_llir(builder, mod, scope = Stone::Scope.top_level)
        # 1. Check if this is a record field access (highest priority)
        return access_record_field(builder, mod, scope) if record_field_access?(mod)

        # Resolve the receiver type for subsequent checks
        receiver_type = resolve_node_type(@receiver, mod)

        # Try different property access strategies
        handle_type_property(builder, mod, scope, receiver_type) ||
          handle_field_list_property(builder, mod, scope, receiver_type) ||
          handle_byte_count(mod) ||
          handle_computed_property(builder, mod, scope, receiver_type) ||
          fail_property_not_found(receiver_type)
      end

      private def handle_type_property(builder, mod, scope, receiver_type)
        return nil unless TYPE_PROPERTIES.include?(@property)
        return nil unless type_receiver?(receiver_type)

        type_ptr = @receiver.to_llir(builder, mod, scope)
        generate_type_property(builder, mod, type_ptr)
      end

      private def type_receiver?(receiver_type)
        # Direct type match
        return true if receiver_type == Stone::Type::Type

        # Check if receiver is a property access that returns Type
        # (handles cases like fields.first.type)
        if @receiver.is_a?(PropertyAccess)
          receiver_property = @receiver.property
          return true if receiver_property == "type"
        end

        false
      end

      TYPE_PROPERTY_GENERATORS = {
        "as_String" => :generate_type_as_string, "size" => :generate_type_size,
        "kind" => :generate_type_kind, "record?" => :generate_type_record_check,
        "primitive?" => :generate_type_primitive_check, "fields" => :generate_type_fields
      }.freeze

      private def generate_type_property(builder, _mod, type_ptr)
        method_name = TYPE_PROPERTY_GENERATORS[@property]
        __send__(method_name, builder, Stone::RTTI.type_struct_type, type_ptr)
      end

      private def generate_type_as_string(builder, type_struct, type_ptr)
        # Load the name pointer from the type struct (field 0)
        name_ptr_ptr = builder.struct_gep2(type_struct, type_ptr, 0, "name_ptr_ptr")
        name_ptr = builder.load2(LLVM::Type.pointer, name_ptr_ptr, "name_ptr")
        # Convert pointer to i64 for Stone's string representation
        builder.ptr2int(name_ptr, LLVM::Int64.type, "name_as_i64")
      end

      private def generate_type_size(builder, type_struct, type_ptr)
        # Load the size field (field 1)
        size_ptr = builder.struct_gep2(type_struct, type_ptr, 1, "size_ptr")
        builder.load2(LLVM::Int64.type, size_ptr, "type_size")
      end

      private def generate_type_kind(builder, type_struct, type_ptr)
        # Load the kind field (field 2) and extend to i64
        kind_ptr = builder.struct_gep2(type_struct, type_ptr, 2, "kind_ptr")
        kind_i8 = builder.load2(LLVM::Int8.type, kind_ptr, "kind_i8")
        builder.zext(kind_i8, LLVM::Int64.type, "type_kind")
      end

      private def generate_type_record_check(builder, type_struct, type_ptr)
        # Check if kind == 1 (record)
        kind_ptr = builder.struct_gep2(type_struct, type_ptr, 2, "kind_ptr")
        kind_i8 = builder.load2(LLVM::Int8.type, kind_ptr, "kind_i8")
        builder.icmp(:eq, kind_i8, LLVM::Int8.from_i(Stone::RTTI::KIND_RECORD), "is_record")
      end

      private def generate_type_primitive_check(builder, type_struct, type_ptr)
        # Check if kind == 0 (primitive)
        kind_ptr = builder.struct_gep2(type_struct, type_ptr, 2, "kind_ptr")
        kind_i8 = builder.load2(LLVM::Int8.type, kind_ptr, "kind_i8")
        builder.icmp(:eq, kind_i8, LLVM::Int8.from_i(Stone::RTTI::KIND_PRIMITIVE), "is_primitive")
      end

      private def generate_type_fields(builder, type_struct, type_ptr)
        fields_ptr_ptr = builder.struct_gep2(type_struct, type_ptr, 3, "fields_ptr_ptr")
        builder.load2(LLVM::Type.pointer, fields_ptr_ptr, "fields_ptr")
      end

      private def handle_field_list_property(builder, mod, scope, receiver_type)
        # Check if receiver type is FieldList or if we can infer it from expression structure
        return nil unless FIELD_LIST_PROPERTIES.include?(@property)
        return nil unless field_list_receiver?(receiver_type)

        field_list_ptr = @receiver.to_llir(builder, mod, scope)
        generate_field_list_property(builder, field_list_ptr)
      end

      private def field_list_receiver?(receiver_type)
        # Direct type match
        return true if receiver_type == Stone::Type::FieldList

        # Check if receiver is a property access that returns FieldList
        # (handles cases like type.fields, fields.first, fields.rest)
        if @receiver.is_a?(PropertyAccess)
          receiver_property = @receiver.property
          return true if receiver_property == "fields" || FIELD_LIST_PROPERTIES.include?(receiver_property)
        end

        # For Reference receivers, we can't easily determine type at compile time
        # Check if any ancestor in property chain indicates FieldList context
        return receiver_references_field_list? if @receiver.is_a?(Reference)

        false
      end

      # Heuristic: if the variable name suggests it's a FieldList value
      # This is a workaround for incomplete type inference
      private def receiver_references_field_list?
        # Common variable names for field lists
        identifier = @receiver.identifier
        identifier.include?("field") || identifier.include?("Field")
      end

      FIELD_LIST_PROPERTY_GENERATORS = {
        "name" => :generate_field_list_name, "type" => :generate_field_list_type,
        "rest" => :generate_field_list_rest
      }.freeze

      private def generate_field_list_property(builder, field_list_ptr)
        return field_list_ptr if @property == "first" # .first returns the FieldList itself

        method_name = FIELD_LIST_PROPERTY_GENERATORS[@property]
        __send__(method_name, builder, Stone::RTTI.field_list_struct_type, field_list_ptr)
      end

      private def generate_field_list_name(builder, field_list_struct, field_list_ptr)
        name_ptr_ptr = builder.struct_gep2(field_list_struct, field_list_ptr, 0, "field_name_ptr_ptr")
        name_ptr = builder.load2(LLVM::Type.pointer, name_ptr_ptr, "field_name_ptr")
        builder.ptr2int(name_ptr, LLVM::Int64.type, "field_name_as_i64")
      end

      private def generate_field_list_type(builder, field_list_struct, field_list_ptr)
        type_ptr_ptr = builder.struct_gep2(field_list_struct, field_list_ptr, 1, "field_type_ptr_ptr")
        builder.load2(LLVM::Type.pointer, type_ptr_ptr, "field_type_ptr")
      end

      private def generate_field_list_rest(builder, field_list_struct, field_list_ptr)
        rest_ptr_ptr = builder.struct_gep2(field_list_struct, field_list_ptr, 2, "field_rest_ptr_ptr")
        builder.load2(LLVM::Type.pointer, rest_ptr_ptr, "field_rest_ptr")
      end

      private def handle_byte_count(mod)
        return nil unless @property == "byte_count"

        string_literal = get_string_literal(mod)
        LLVM::Int64.from_i(string_literal.bytesize) if string_literal
      end

      private def handle_computed_property(builder, mod, scope, receiver_type)
        return nil unless receiver_type

        computed_func = lookup_computed_property_function(mod, receiver_type)
        return nil unless computed_func

        receiver_value = @receiver.to_llir(builder, mod, scope)
        builder.call(computed_func, receiver_value, "#{@property}_result")
      end

      private def lookup_computed_property_function(mod, receiver_type)
        mod.lookup_function("#{receiver_type.name}@#{@property}")
      end

      private def fail_property_not_found(receiver_type)
        type_name = receiver_type&.name || "Unknown"
        fail Stone::PropertyError, "Property '#{@property}' not found for type '#{type_name}'"
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

        # Check if receiver is a PropertyAccess that returns a record type
        return receiver_property_returns_record?(mod) if @receiver.is_a?(PropertyAccess)

        false
      end

      private def receiver_property_returns_record?(mod)
        field_type = get_receiver_field_type(mod)
        field_type && mod.record_type?(field_type)
      end

      private def get_receiver_field_type(mod)
        return nil unless @receiver.is_a?(PropertyAccess)

        # Get the record type that the receiver's receiver is accessing
        parent_record_type = @receiver.get_record_type_name(mod)
        return nil unless parent_record_type

        # Look up the field type for the receiver's property
        record_def = mod.record_types[parent_record_type]
        return nil unless record_def

        field = record_def.fields.find { |f| f[:name] == @receiver.property }
        field&.dig(:type)
      end

      private def access_record_field(builder, mod, scope)
        record_type_name = get_record_type_name(mod)
        record_def = lookup_record_definition(mod, record_type_name)
        field_index = get_field_index(record_def, record_type_name)

        # Evaluate the receiver to get the record struct
        receiver_value = @receiver.to_llir(builder, mod, scope)

        # If receiver is a pointer (recursive field), load the struct first
        if receiver_value.type.kind == :pointer
          struct_type = record_def.llvm_type(mod)
          receiver_value = builder.load2(struct_type, receiver_value, "loaded_struct")
        end

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

      def get_record_type_name(mod)
        case @receiver
        when Reference
          mod.record_instance_type(@receiver.identifier)
        when FunctionCall
          @receiver.function_name
        when PropertyAccess
          # Receiver is a PropertyAccess - get the field type it returns
          get_receiver_field_type(mod)
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
