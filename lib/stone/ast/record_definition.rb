require "stone/ast/expression"


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

      def to_llir(_builder, mod)
        # Generate and return a constructor function that creates instances of this record
        generate_constructor_function(mod)
      end

      def field_names
        @fields.map { |f| f[:name] }
      end

      def field_types
        @fields.map { |f| f[:type] }
      end

      def field_index(field_name)
        field_names.index(field_name)
      end

      def llvm_type
        # Convert field types to LLVM types
        llvm_field_types = @fields.map { |field| llvm_type_for(field[:type]) }
        LLVM::Type.struct(llvm_field_types, false)
      end

      def to_s
        field_strs = @fields.map { |f| "#{f[:name]} :: #{f[:type]}" }
        "Record(#{field_strs.join(', ')})"
      end

      def type(_context = nil)
        return nil unless @assigned_name

        record_type = Stone::Type::Registry.lookup(@assigned_name)
        return nil unless record_type

        param_types = @fields.map { |f| Stone::Type::Registry.lookup(f[:type]) }
        return nil if param_types.any?(&:nil?)

        Stone::Type.function(param_types:, return_type: record_type)
      end

      private def llvm_type_for(type_name)
        case type_name
        when "Int" then LLVM::Int64
        when "Bool" then LLVM::Int1
        when "String"
          # Stone currently represents strings as i64 pointers, not as {ptr, i64} structs
          # This is for JIT compatibility
          LLVM::Int64
        else
          fail "Unknown type: #{type_name}"
        end
      end

      private def generate_constructor_function(mod)
        func_name = "__record_constructor_#{object_id}__"
        func_type = constructor_function_type

        mod.functions.add(func_name, func_type).tap do |func|
          build_constructor_body(func)
        end
      end

      private def constructor_function_type
        # Constructor function signature: (field_types...) -> struct_type
        field_llvm_types = @fields.map { |field| llvm_type_for(field[:type]) }
        LLVM::Type.function(field_llvm_types, llvm_type)
      end

      private def build_constructor_body(func)
        func.basic_blocks.append("entry").build do |builder|
          # Start with null/undef struct value
          struct_value = llvm_type.null

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
