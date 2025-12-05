require "stone/ast"


module Stone
  class AST
    class Reference < Stone::AST

      attr_reader :identifier

      def initialize(identifier, type: nil)
        @identifier = identifier
        @type = type
        @name = :reference
      end

      def type(mod = nil)
        return @type if @type
        return nil unless mod

        # Check if it's a parameter (in current lambda context)
        if mod.lambda_param_storage&.key?(identifier)
          return llvm_type_to_stone_type(mod.lambda_param_storage[identifier].allocated_type)
        end

        # Check if it's a global constant
        if (global = mod.globals[identifier])
          return llvm_type_to_stone_type(global.value_type)
        end

        nil
      end

      private

      def llvm_type_to_stone_type(llvm_type)
        case llvm_type.kind
        when :integer
          llvm_type.width == 1 ? "Bool" : "Int"
        when :pointer
          "String" # String type is pointer to i8 (in struct, but we return pointer)
        else
          nil
        end
      end

      def to_llir(builder, mod)
        lookup_parameter(builder, mod) ||
          lookup_global(builder, mod) ||
          lookup_function(mod) ||
          fail_with_reference_error
      end

      private def lookup_parameter(builder, mod)
        param_storage = mod.lambda_param_storage
        return nil unless param_storage && param_storage[identifier]

        builder.load(param_storage[identifier], identifier)
      end

      private def lookup_global(builder, mod)
        global = mod.globals[identifier]
        return nil unless global

        builder.load(global, identifier)
      end

      private def lookup_function(mod)
        mod.lookup_function(identifier)
      end

      private def fail_with_reference_error
        fail Stone::ReferenceError, "undefined constant, variable, or function: #{identifier}"
      end

      def to_s
        identifier
      end

    end
  end
end
