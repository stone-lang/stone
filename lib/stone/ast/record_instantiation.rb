require "stone/ast/expression"
require "stone/error/arity_error"
require "stone/rtti"


module Stone
  class AST
    class RecordInstantiation < Stone::AST::Expression

      attr_reader :record_type_name, :field_values, :record_definition

      def initialize(record_type_name, field_values)
        @name = :record_instantiation
        @record_type_name = record_type_name
        @field_values = field_values
        @record_definition = nil
      end

      def to_llir(builder, mod, scope = Stone::Scope.top_level)
        record_def = mod.record_types[@record_type_name]
        fail "Unknown record type: #{@record_type_name}" unless record_def

        # Store record definition for later access
        @record_definition = record_def

        # Verify field count matches
        if @field_values.size != record_def.fields.size
          fail Stone::ArityError, "wrong number of arguments for #{@record_type_name} (given #{@field_values.size}, expected #{record_def.fields.size})"
        end

        # Evaluate each field value
        llvm_values = @field_values.map { |field_ast| field_ast.to_llir(builder, mod, scope) }

        # Convert struct values to pointers for record-typed fields
        llvm_values = convert_structs_to_pointers(builder, mod, record_def, llvm_values)

        # Create struct value
        create_struct(record_def.llvm_type(mod), llvm_values, builder)
      end

      def to_s
        "#{@record_type_name}(#{@field_values.map(&:to_s).join(', ')})"
      end

      def type(_context = nil)
        Stone::Type::Registry.lookup(@record_type_name)
      end

      private def verify_field_type(field_name, expected_type, llvm_value)
        expected_llvm_type = llvm_type_for(expected_type)
        actual_llvm_type = llvm_value.type

        return if types_match?(expected_llvm_type, actual_llvm_type)

        fail "Type mismatch for field '#{field_name}': expected #{expected_type}, got #{actual_llvm_type}"
      end

      private def types_match?(expected, actual)
        expected.to_s == actual.to_s
      end

      private def llvm_type_for(type_name)
        case type_name
        when "Int" then LLVM::Int64
        when "Bool" then LLVM::Int1
        when "String" then Stone::Type::String.llvm_type
        else
          fail "Unknown type: #{type_name}"
        end
      end

      private def convert_structs_to_pointers(builder, mod, record_def, llvm_values)
        llvm_values.each_with_index.map do |value, index|
          convert_field_value(builder, mod, record_def.fields[index], value, index)
        end
      end

      private def convert_field_value(builder, mod, field, value, index)
        if field.union_annotation?
          union_type = field.resolve_type
          return wrap_in_tagged_union(builder, mod, value, @field_values[index], union_type)
        end
        return allocate_and_store(builder, value) if needs_pointer_conversion?(field, mod, value)

        value
      end

      private def needs_pointer_conversion?(field, mod, value)
        field_expects_pointer?(field.type_name, mod) && value.type.kind == :struct
      end

      private def wrap_in_tagged_union(builder, mod, llvm_value, ast_value, union_type)
        value_type = ast_value.type(Stone::TypeContext.new(mod))
        type_constant = Stone::RTTI.type_constant_for(mod, value_type)

        # Allocate union on stack
        union_ptr = builder.alloca(union_type.llvm_type, "union_alloca")

        # Store type tag (field 0)
        tag_ptr = builder.struct_gep2(union_type.llvm_type, union_ptr, 0, "tag_ptr")
        builder.store(type_constant, tag_ptr)

        # Store payload (field 1) - no ptr2int needed
        payload_ptr = builder.struct_gep2(union_type.llvm_type, union_ptr, 1, "payload_ptr")
        store_payload(builder, payload_ptr, llvm_value, value_type)

        # Load and return the union value
        builder.load2(union_type.llvm_type, union_ptr, "union_value")
      end

      private def store_payload(builder, payload_ptr, llvm_value, _value_type)
        value_to_store = llvm_value.type.kind == :struct ? allocate_and_store(builder, llvm_value) : llvm_value
        builder.store(value_to_store, payload_ptr)
      end

      private def field_expects_pointer?(field_type_name, mod)
        field_type_name == @record_type_name || mod.record_type?(field_type_name)
      end

      private def allocate_and_store(builder, struct_value)
        ptr = builder.alloca(struct_value.type, "nested_record")
        builder.store(struct_value, ptr)
        ptr
      end

      private def create_struct(struct_type, values, builder)
        struct_value = struct_type.null

        values.each_with_index do |value, index|
          struct_value = builder.insert_value(struct_value, value, index)
        end

        struct_value
      end

    end
  end
end
