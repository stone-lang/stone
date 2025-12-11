require "stone/ast"
require "stone/error/type_error"


module Stone
  class AST
    class Reference < Stone::AST

      attr_reader :identifier

      def initialize(identifier, type: nil)
        @identifier = identifier
        @type = type
        @name = :reference
      end

      def type(context = nil)
        return @type if @type
        return nil unless context

        type_from_context(context) || type_from_module(context)
      end

      private def type_from_context(context)
        return nil unless context.is_a?(Stone::TypeContext)

        result = context.lookup(@identifier)
        fail Stone::TypeError, "Unknown identifier: #{@identifier}" unless result

        result
      end

      private def type_from_module(context)
        # Fallback to old module-based lookup for backwards compatibility during migration
        type_from_record_instance(context) || type_from_parameter(context) || type_from_string_constant(context) || type_from_global(context)
      end

      def record_instance?(mod)
        mod.record_instance?(identifier)
      end

      def to_llir(builder, mod)
        lookup_parameter(builder, mod) ||
          lookup_global(builder, mod) ||
          lookup_function(mod) ||
          lookup_record_type(mod) ||
          fail_with_reference_error
      end

      def to_s
        identifier
      end

      private def type_from_parameter(mod)
        return unless mod.lambda_param_storage&.key?(identifier)

        llvm_type_to_stone_type(mod.lambda_param_storage[identifier].allocated_type)
      end

      private def type_from_string_constant(mod)
        "String" if mod.string_constant?(identifier)
      end

      private def type_from_record_instance(mod)
        mod.record_instance_type(identifier) if mod.record_instance?(identifier)
      end

      private def type_from_global(mod)
        global = mod.globals[identifier]
        return unless global

        # In LLVM 21+, globals use opaque pointers, so check the initializer's type
        llvm_type = global.initializer&.type
        llvm_type_to_stone_type(llvm_type) if llvm_type
      end

      private def llvm_type_to_stone_type(llvm_type)
        return nil unless llvm_type

        actual_type = unwrap_pointer_type(llvm_type)
        stone_type_from_llvm_kind(actual_type)
      end

      private def unwrap_pointer_type(llvm_type)
        llvm_type.kind == :pointer ? llvm_type.element_type : llvm_type
      end

      private def stone_type_from_llvm_kind(llvm_type)
        case llvm_type.kind
        when :integer then llvm_type.width == 1 ? "Bool" : "Int"
        when :pointer, :struct then "String"
        end
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

      private def lookup_record_type(mod)
        # Record types aren't really values, but if referenced, return a dummy value
        # This allows code like "Person := Record(...)\nPerson" to not fail
        return LLVM::Int64.from_i(0) if mod.record_type?(identifier)

        nil
      end

      private def fail_with_reference_error
        fail Stone::ReferenceError, "undefined constant, variable, or function: #{identifier}"
      end

    end
  end
end
