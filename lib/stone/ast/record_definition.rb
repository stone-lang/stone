require "stone/ast/expression"
require "stone/error/type_error"
require "stone/rtti"


module Stone
  class AST
    # TODO: Records should be first-class Type objects, not AST nodes.
    # When the type system is refactored:
    # - Record types should be instances of a RecordType class
    # - Record types should be global constants with properties
    # - Record types should have vtables for polymorphic operations
    # - Record instantiation should work like any other function call
    class RecordDefinition < Stone::AST::Expression

      attr_reader :fields
      attr_accessor :assigned_name

      # fields is an array of { name: "field_name", type: "TypeName" } hashes
      def initialize(fields)
        @name = :record_definition
        @fields = fields
        @assigned_name = nil
      end

      def to_llir(_builder, mod, scope = Stone::Scope.top_level)
        # Validate all field types resolve in current scope
        validate_field_types(scope, mod)
        # Generate the type constant for this record
        generate_type_constant(mod, scope) if @assigned_name
        # Generate and return a constructor function that creates instances of this record
        generate_constructor_function(mod, scope)
      end

      private def generate_type_constant(mod, scope)
        struct_type = llvm_type(mod, scope)
        size_bytes = calculate_struct_size(struct_type)
        equals_fn = generate_record_equals_fn(mod, struct_type)
        Stone::RTTI.generate_record_type_constant(mod, @assigned_name, size_bytes, @fields, equals_fn)
      end

      private def generate_record_equals_fn(mod, struct_type)
        fn_name = "__#{@assigned_name}_equals__"
        mod.functions.add(fn_name, Stone::RTTI.equals_fn_type).tap do |func|
          build_record_equals_body(func, mod, struct_type)
        end
      end

      private def build_record_equals_body(func, mod, struct_type)
        func.basic_blocks.append("entry").build do |builder|
          result = compare_all_record_fields(builder, func, mod, struct_type)
          builder.ret(result)
        end
      end

      private def compare_all_record_fields(builder, func, mod, struct_type)
        comparable = @fields.reject { |f| Stone::AST::FieldHelpers.union_annotation?(f[:type]) }
        result = LLVM::TRUE
        comparable.each do |field|
          a_val, b_val = field_value_ptrs(builder, struct_type, field, func)
          a_val, b_val = load_if_record_field(builder, field, mod, a_val, b_val)
          fn = lookup_field_equals_fn(mod, field)
          field_eq = builder.call2(Stone::RTTI.equals_fn_type, fn, a_val, b_val, "#{field[:name]}_eq")
          result = builder.and(result, field_eq, "and_#{field[:name]}")
        end
        result
      end

      private def field_value_ptrs(builder, struct_type, field, func)
        index = @fields.index(field)
        a = builder.struct_gep2(struct_type, func.params[0], index, "a_#{field[:name]}")
        b = builder.struct_gep2(struct_type, func.params[1], index, "b_#{field[:name]}")
        [a, b]
      end

      private def load_if_record_field(builder, field, mod, a_val, b_val)
        return [a_val, b_val] unless record_typed_field?(field, mod)

        [
          builder.load2(LLVM::Type.pointer, a_val, "a_#{field[:name]}_ptr"),
          builder.load2(LLVM::Type.pointer, b_val, "b_#{field[:name]}_ptr")
        ]
      end

      private def record_typed_field?(field, mod)
        type_name = Stone::AST::FieldHelpers.field_type_name(field)
        type_name == @assigned_name || mod.record_type?(type_name)
      end

      private def lookup_field_equals_fn(mod, field)
        type_name = Stone::AST::FieldHelpers.field_type_name(field)
        fn_name = "__#{type_name}_equals__"
        mod.functions[fn_name] || fail("No equals function found for type: #{type_name}")
      end

      # Calculate size based on field types (simplified -- assumes packed alignment)
      private def calculate_struct_size(struct_type)
        struct_type.element_types.sum { |elem_type| element_type_size(elem_type) }
      end

      private def element_type_size(llvm_type)
        case llvm_type.kind
        when :integer then (llvm_type.width + 7) / 8  # Round up to bytes
        when :pointer then 8  # 64-bit pointers
        when :struct then llvm_type.element_types.sum { |t| element_type_size(t) }
        else 8  # Default to 8 bytes
        end
      end

      private def validate_field_types(scope, mod)
        @fields.each { |field| validate_field_type(field, scope, mod) }
      end

      private def validate_field_type(field, scope, mod)
        return if Stone::AST::FieldHelpers.union_annotation?(field[:type])

        type_name = Stone::AST::FieldHelpers.field_type_name(field)
        return if known_type?(type_name, scope, mod)

        fail Stone::TypeError, "Unknown type: #{type_name}"
      end

      private def known_type?(type_name, scope, mod)
        type_name == @assigned_name || mod&.record_type?(type_name) || scope.lookup_type(type_name)
      end

      def field_names
        @fields.map { |f| f[:name] }
      end

      def field_types
        @fields.map { |f| Stone::AST::FieldHelpers.field_type_name(f) }
      end

      def field_type_annotation(field_name)
        field = @fields.find { |f| f[:name] == field_name }
        field&.dig(:type)
      end

      def field_index(field_name)
        field_names.index(field_name)
      end

      def llvm_type(mod = nil, scope = Stone::Scope.top_level)
        # Convert field types to LLVM types
        llvm_field_types = @fields.map { |field| llvm_type_for_field(field, mod, scope) }
        LLVM::Type.struct(llvm_field_types, false)
      end

      def to_s
        field_strs = @fields.map { |f| "#{f[:name]} :: #{f[:type_name]}" }
        "Record(#{field_strs.join(', ')})"
      end

      def type(_context = nil)
        return nil unless @assigned_name

        record_type = Stone::Type::Registry.lookup(@assigned_name)
        return nil unless record_type

        param_types = @fields.map { |f| resolve_field_stone_type(f) }
        return nil if param_types.any?(&:nil?)

        Stone::Type.function(param_types:, return_type: record_type)
      end

      private def resolve_field_stone_type(field)
        Stone::AST::FieldHelpers.resolve_field_type(field)
      end

      # Returns the LLVM type for a field. Handles union types, primitives, and record types.
      private def llvm_type_for_field(field, mod, scope)
        return llvm_type_for_union(field[:type]) if Stone::AST::FieldHelpers.union_annotation?(field[:type])

        type_name = Stone::AST::FieldHelpers.field_type_name(field)
        resolve_simple_llvm_type(type_name, mod, scope)
      end

      private def resolve_simple_llvm_type(type_name, mod, scope)
        return LLVM::Type.ptr if record_reference?(type_name, mod)
        return Stone::Type::Registry.lookup(type_name).llvm_type if primitive_type?(type_name)
        return LLVM::Type.ptr if scope.lookup_type(type_name)

        fail Stone::TypeError, "Unknown type: #{type_name}"
      end

      private def record_reference?(type_name, mod)
        type_name == @assigned_name || mod&.record_type?(type_name)
      end

      private def primitive_type?(type_name)
        Stone::Type::Registry.lookup(type_name)
      end

      private def llvm_type_for_union(annotation)
        stone_type = annotation.to_type(Stone::Type::Registry)
        stone_type.llvm_type
      end

      private def generate_constructor_function(mod, scope)
        func_name = "__record_constructor_#{object_id}__"
        func_type = constructor_function_type(mod, scope)

        mod.functions.add(func_name, func_type).tap do |func|
          build_constructor_body(func, mod, scope)
        end
      end

      private def constructor_function_type(mod, scope)
        # Constructor function signature: (field_types...) -> struct_type
        field_llvm_types = @fields.map { |field| llvm_type_for_field(field, mod, scope) }
        LLVM::Type.function(field_llvm_types, llvm_type(mod, scope))
      end

      private def build_constructor_body(func, mod, scope)
        func.basic_blocks.append("entry").build do |builder|
          # Start with null/undef struct value
          struct_value = llvm_type(mod, scope).null

          # Insert each field value from function parameters
          @fields.each_with_index do |_field, index|
            struct_value = builder.insert_value(struct_value, func.params[index], index)
          end

          builder.ret(struct_value)
        end
      end

    end
  end
end
