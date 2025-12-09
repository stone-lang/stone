require "stone/ast"


module Stone
  class AST
    # TODO: Records should be first-class Type objects, not AST nodes.
    # When the type system is refactored:
    # - Record types should be instances of a RecordType class
    # - Record types should be global constants with properties
    # - Record types should have vtables for polymorphic operations
    # - Record instantiation should work like any other function call
    class RecordDefinition < Stone::AST

      attr_reader :fields

      # fields is an array of { name: "field_name", type: "TypeName" } hashes
      def initialize(fields)
        @name = :record_definition
        @fields = fields
      end

      def to_llir(_builder, _mod)
        # Record definitions don't generate LLVM IR directly.
        # They are metadata that gets stored in the module for later use.
        # Return a dummy value for now (records are used via constants).
        LLVM::Int64.from_i(0)
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

    end
  end
end
