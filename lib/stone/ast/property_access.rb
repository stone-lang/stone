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

        # 2. Check if receiver is a union containing record(s) - enables chained access like o.value.x
        return access_field_on_union_record(builder, mod, scope) if receiver_is_union_with_record?(mod)

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
        # Return pointer directly - no ptr2int (CHERI-safe)
        builder.load2(LLVM::Type.pointer, name_ptr_ptr, "name_ptr")
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
        # Return pointer directly - no ptr2int (CHERI-safe)
        builder.load2(LLVM::Type.pointer, name_ptr_ptr, "field_name_ptr")
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

      # Check if receiver returns a union type that contains record(s)
      # This enables chained access like o.value.x where value is Point | Null
      private def receiver_is_union_with_record?(mod)
        receiver_type = safe_get_receiver_type(mod)
        return false unless receiver_type&.union?

        # Check if any non-null alternative is a record with this property
        receiver_type.alternatives.any? do |alt|
          next false if alt.name == "Null"

          alt.record? && alt.property_return_type(@property)
        end
      end

      # Safely get the receiver's type, returning nil if type resolution fails.
      # This prevents errors during speculative checks like receiver_is_union_with_record?.
      private def safe_get_receiver_type(mod)
        @receiver.type(mod)
      rescue Stone::PropertyError, Stone::TypeError
        nil
      end

      # Access a field on a record extracted from a union type
      # For o.value.x where value is Point | Null:
      # The receiver (o.value) already extracts the record pointer from the union
      # via extract_homogeneous_union, so we just use that pointer directly.
      private def access_field_on_union_record(builder, mod, scope)
        receiver_type = @receiver.type(mod)
        record_type = find_record_type_in_union(receiver_type, mod)
        record_def = mod.record_types[record_type.name]

        # Get the already-extracted record pointer from the receiver
        # (receiver.to_llir already handles union extraction)
        record_ptr = @receiver.to_llir(builder, mod, scope)

        # Load the record struct and access the field
        record_struct = builder.load2(record_def.llvm_type(mod), record_ptr, "record_from_union")
        field_index = record_def.field_index(@property)
        builder.extract_value(record_struct, field_index, "#{@property}_value")
      end

      private def find_record_type_in_union(union_type, _mod)
        union_type.alternatives.find do |alt|
          next false if alt.name == "Null"

          alt.record? && alt.property_return_type(@property)
        end
      end

      private def get_receiver_field_type(mod)
        return nil unless @receiver.is_a?(PropertyAccess)

        # Get the record type that the receiver's receiver is accessing
        parent_record_type = @receiver.get_record_type_name(mod)
        return nil unless parent_record_type

        # Look up the field type for the receiver's property
        record_def = mod.record_types[parent_record_type]
        return nil unless record_def

        field = record_def.fields.find { |f| f.name == @receiver.property }
        field&.type_name
      end

      private def access_record_field(builder, mod, scope)
        record_def = lookup_record_definition(mod, get_record_type_name(mod))
        receiver_value = load_receiver_struct(builder, mod, scope, record_def)
        field_index = get_field_index(record_def, record_def.assigned_name)
        field_value = builder.extract_value(receiver_value, field_index, "#{@property}_value")
        maybe_extract_union_payload(builder, mod, field_value, record_def)
      end

      private def load_receiver_struct(builder, mod, scope, record_def)
        receiver_value = @receiver.to_llir(builder, mod, scope)
        return receiver_value unless receiver_value.type.kind == :pointer

        builder.load2(record_def.llvm_type(mod), receiver_value, "loaded_struct")
      end

      private def maybe_extract_union_payload(builder, mod, field_value, record_def)
        annotation = record_def.field_type_annotation(@property)
        return field_value unless Stone::AST::FieldHelpers.union_annotation?(annotation)

        union_type = annotation.to_type(Stone::Type::Registry)
        extract_union_payload(builder, mod, field_value, union_type)
      end

      private def extract_union_payload(builder, mod, union_value, union_type)
        # For unions that need runtime type tag (e.g., Bool | Int), allocate on heap and return pointer.
        # Ruby reads type tag and payload from heap memory to interpret correctly.
        return heap_allocate_union(builder, mod, union_value, union_type) if union_type.needs_runtime_type_tag?

        # For homogeneous unions, extract the payload with phi merge
        return extract_homogeneous_union(builder, mod, union_value, union_type) if union_type.homogeneous?

        # For mixed-type unions (e.g., Int | String), extract payload as i64.
        # Both Int (8 bytes) and String pointers (8 bytes) fit in i64.
        # Ruby-side conversion uses the type tag to interpret the value correctly.
        extract_mixed_union_payload(builder, mod, union_value, union_type)
      end

      # Allocate union on heap using malloc, store the value, return pointer.
      # Ruby can read the type tag and payload from this memory.
      # NOTE: This memory is never freed, but since it only happens at the end of
      # program evaluation (returning values to Ruby), the leak is acceptable.
      private def heap_allocate_union(builder, mod, union_value, union_type)
        # Get or declare malloc
        malloc_func = mod.functions["malloc"] || declare_malloc(mod)

        # Allocate memory for the union struct (16 bytes: 8 for ptr, 8 for payload)
        size = LLVM::Int64.from_i(union_type.size_bytes)
        heap_ptr = builder.call(malloc_func, size, "union_heap_ptr")

        # Store the union value to heap memory
        builder.store(union_value, heap_ptr)

        heap_ptr
      end

      private def declare_malloc(mod)
        malloc_type = LLVM::Type.function([LLVM::Int64.type], LLVM::Type.pointer, varargs: false)
        mod.functions.add("malloc", malloc_type)
      end

      private def extract_mixed_union_payload(builder, _mod, union_value, union_type)
        # Allocate union on stack to get pointer for GEP
        union_ptr = builder.alloca(union_type.llvm_type, "mixed_union_for_extract")
        builder.store(union_value, union_ptr)

        # Get payload pointer (index 1 in the {ptr, [N x i8]} struct)
        payload_ptr = builder.struct_gep2(union_type.llvm_type, union_ptr, 1, "mixed_payload_ptr")

        # Load payload as i64 (works for both Int values and pointer addresses)
        builder.load2(LLVM::Int64.type, payload_ptr, "mixed_payload_i64")
      end

      private def extract_homogeneous_union(builder, mod, union_value, union_type)
        # Allocate union on stack to get pointer for GEP
        union_ptr = builder.alloca(union_type.llvm_type, "union_for_extract")
        builder.store(union_value, union_ptr)

        # Get type tag to determine how to interpret payload
        tag_ptr = builder.struct_gep2(union_type.llvm_type, union_ptr, 0, "extract_tag_ptr")
        type_tag = builder.load2(LLVM::Type.pointer, tag_ptr, "type_tag")

        # Get payload pointer
        payload_ptr = builder.struct_gep2(union_type.llvm_type, union_ptr, 1, "extract_payload_ptr")

        # Generate runtime type dispatch to extract payload correctly
        extract_with_type_dispatch(builder, mod, type_tag, payload_ptr, union_type)
      end

      private def extract_with_type_dispatch(builder, mod, type_tag, payload_ptr, union_type)
        dispatch = TypeDispatchBuilder.new(builder, mod, union_type)
        result_type = union_type.common_llvm_result_type
        dispatch.build_switch(type_tag)
        phi_incoming = dispatch.build_extraction_blocks(payload_ptr) { |alt| load_payload_as_type(builder, payload_ptr, alt, result_type) }
        dispatch.build_merge_phi(phi_incoming)
      end

      # Builds LLVM switch/phi dispatch for union type extraction
      class TypeDispatchBuilder
        def initialize(builder, mod, union_type)
          @builder = builder
          @mod = mod
          @union_type = union_type
          @alternatives = union_type.alternatives
          @result_type = union_type.common_llvm_result_type
          create_basic_blocks
        end

        def build_switch(type_tag)
          cases = @alternatives.each_with_index.to_h { |alt, i| [Stone::RTTI.type_constant_for(@mod, alt), @alt_blocks[i]] }
          @builder.switch(type_tag, default_block, cases)
        end

        def build_extraction_blocks(_payload_ptr)
          @alternatives.each_with_index.to_h do |alt, index|
            @builder.position_at_end(@alt_blocks[index])
            raw_value = yield(alt)
            converted = convert_to_result_type(raw_value)
            @builder.br(@merge_block)
            [@alt_blocks[index], converted]
          end
        end

        def build_merge_phi(phi_incoming)
          @builder.position_at_end(@merge_block)
          @builder.phi(@result_type, phi_incoming, "extracted_payload")
        end

        private def create_basic_blocks
          current_func = @builder.insert_block.parent
          @alt_blocks = @alternatives.map { |alt| current_func.basic_blocks.append("extract_#{alt.name.downcase}") }
          @merge_block = current_func.basic_blocks.append("extract_merge")
        end

        private def default_block
          null_idx = @alternatives.index { |alt| alt.name == "Null" }
          null_idx ? @alt_blocks[null_idx] : @alt_blocks.first
        end

        # Convert value to match @result_type for phi merge.
        # Only called for homogeneous unions where all alternatives have compatible types.
        # - If result is i64: integers get widened, Null returns i64(0)
        # - If result is ptr: all values are already pointers
        # No int2ptr or ptr2int conversions needed (CHERI-safe).
        private def convert_to_result_type(value)
          return value if value.type == @result_type
          return widen_int(value) if value.type.kind == :integer && @result_type.kind == :integer

          value
        end

        private def widen_int(value)
          value.type.width < 64 ? @builder.zext(value, LLVM::Int64.type, "zext_to_i64") : value
        end
      end

      private def load_payload_as_type(builder, payload_ptr, type, result_type)
        if type.name == "Null"
          # Return appropriate zero value based on result type
          return result_type.kind == :pointer ? LLVM::Type.pointer.null_pointer : LLVM::Int64.from_i(0)
        end

        builder.load2(type.payload_llvm_type, payload_ptr, "#{type.name.downcase}_payload")
      end

      # Check if this property access is on a union-typed field (for Type.of() support)
      def union_field_access?(mod)
        return false unless record_field_access?(mod)

        record_type_name = get_record_type_name(mod)
        record_def = mod.record_types[record_type_name]
        return false unless record_def

        field_annotation = record_def.field_type_annotation(@property)
        Stone::AST::FieldHelpers.union_annotation?(field_annotation)
      end

      # Extract the type tag from a union field (for Type.of() support)
      def extract_union_type_tag(builder, mod, scope)
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

        # Extract the union struct from the record
        union_value = builder.extract_value(receiver_value, field_index, "#{@property}_union")

        # Extract the type tag (index 0) from the union struct
        builder.extract_value(union_value, 0, "union_type_tag")
      end

      def returns_string_field?(mod)
        return false unless record_field_access?(mod)

        record_type_name = get_record_type_name(mod)
        record_def = mod.record_types[record_type_name]
        return false unless record_def

        field_def = record_def.fields.find { |f| f.name == @property }
        field_def && field_def.type_name == "String"
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
