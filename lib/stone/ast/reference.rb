require "stone/ast/expression"
require "stone/error/type_error"


module Stone
  class AST
    class Reference < Stone::AST::Expression

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

        context.lookup(@identifier)
      end

      private def type_from_module(context)
        # Fallback to old module-based lookup for backwards compatibility during migration
        mod = context.is_a?(Stone::TypeContext) ? context.llvm_module : context
        return nil unless mod

        type_from_record_instance(mod) || type_from_parameter(mod) || type_from_string_constant(mod) || type_from_global(mod)
      end

      def record_instance?(mod)
        mod.record_instance?(identifier)
      end

      def to_llir(builder, mod, scope = Stone::Scope.top_level)
        # Check lambda parameters first - they should shadow outer scope definitions
        lookup_parameter(builder, mod) ||
          lookup_in_scope(scope) ||
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
        Stone::Type::String if mod.string_constant?(identifier)
      end

      private def type_from_record_instance(mod)
        return unless mod.record_instance?(identifier)

        type_name = mod.record_instance_type(identifier)
        Stone::Type::Registry.lookup(type_name)
      end

      private def type_from_global(mod)
        global = mod.globals[identifier]
        return unless global

        # Check if the initializer is a null pointer (NULL constant)
        initializer = global.initializer
        return Stone::Type::Null if null_pointer?(initializer)

        # In LLVM 21+, globals use opaque pointers, so check the initializer's type
        llvm_type = initializer&.type
        llvm_type_to_stone_type(llvm_type) if llvm_type
      end

      private def null_pointer?(value)
        return false unless value

        value.type.kind == :pointer && value.null?
      end

      private def llvm_type_to_stone_type(llvm_type)
        return nil unless llvm_type

        llvm_kind_to_stone_type(llvm_type)
      end

      # Maps LLVM type kinds to Stone types.
      # Note: Record instances are handled by type_from_record_instance BEFORE this is called,
      # so :struct here represents Stone strings (which use struct {i64 len, i8* data}).
      private def llvm_kind_to_stone_type(llvm_type)
        case llvm_type.kind
        when :integer then llvm_type.width == 1 ? Stone::Type::Bool : Stone::Type::Int
        when :pointer, :struct then Stone::Type::String
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

      private def lookup_in_scope(scope)
        definition = scope&.lookup(identifier)
        definition&.dig(:value)
      end

      private def fail_with_reference_error
        fail Stone::ReferenceError, "undefined constant, variable, or function: #{identifier}"
      end

    end
  end
end
