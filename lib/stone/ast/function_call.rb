require "stone/ast/expression"
require "stone/libc"
require "stone/error/argument_error"
require "stone/rtti"


module Stone
  class AST
    class FunctionCall < Stone::AST::Expression

      attr_reader :function_name, :arguments

      def initialize(function_name, arguments)
        @function_name = function_name
        @arguments = arguments
        @name = :function_call
      end

      def to_llir(builder, mod, scope = Stone::Scope.top_level)
        # TODO: Record instantiation should not be special-cased here.
        # When the type system is refactored, record constructors should be
        # regular functions, and this check should be removed.
        return instantiate_record(builder, mod, scope) if mod.record_type?(function_name)

        # Generic type instantiation: Box(Int) → creates specialized record type
        return instantiate_generic_type(builder, mod, scope) if mod.generic_type?(function_name)

        # Equality operators box arguments with type tags for runtime dispatch
        return generate_equality_call(builder, mod, scope) if equality_operator?

        # For chained comparisons, generate inline comparison logic
        return generate_chained_comparison(builder, mod, scope) if chained_comparison?

        # For chained boolean operations, generate inline logic
        return generate_chained_boolean(builder, mod, scope) if chained_boolean?

        # Regular function call
        generate_function_call(builder, mod, scope)
      end

      def to_s
        "#{function_name}(#{arguments.join(', ')})"
      end

      def type(context = nil)
        return Stone::Type::Bool if comparison_operator? || equality_operator? || boolean_operator?
        return record_constructor_type if context&.record_type?(function_name)

        function_return_type
      end

      private def record_constructor_type
        Stone::Type::Registry.lookup(function_name)
      end

      private def function_return_type
        Stone::Type::Registry.lookup(function_name)&.return_type
      end

      private def generate_function_call(builder, mod, scope)
        func = mod.lookup_function(function_name)
        fail Stone::ReferenceError, "undefined function: #{function_name}" unless func

        validate_argument_count(func.function_type.argument_types.size)
        args = evaluate_arguments(builder, mod, scope)
        builder.call(func, *args, "#{function_name}_result")
      end

      # Box each argument as (type_tag, value_ptr) for RTTI-based equality dispatch
      private def generate_equality_call(builder, mod, scope)
        validate_argument_count(2)
        arg_values = evaluate_arguments(builder, mod, scope)
        context = Stone::TypeContext.new(mod, scope:)
        boxed_args = box_equality_arguments(builder, mod, context, arg_values)
        func = mod.lookup_function(function_name)
        builder.call(func, *boxed_args, "#{function_name}_result")
      end

      private def box_equality_arguments(builder, mod, context, arg_values)
        arguments.zip(arg_values).flat_map do |ast_node, llvm_value|
          box_for_equality(builder, mod, context, ast_node, llvm_value)
        end
      end

      private def box_for_equality(builder, mod, context, ast_node, llvm_value)
        stone_type = infer_stone_type(ast_node, context, llvm_value)
        type_tag = resolve_type_tag(builder, mod, stone_type, llvm_value)
        value_ptr = box_value(builder, llvm_value)
        [type_tag, value_ptr]
      end

      # Infer the Stone type for an AST node, falling back to LLVM type inspection
      private def infer_stone_type(ast_node, context, llvm_value)
        result = begin
          ast_node.type(context)
        rescue Stone::PropertyError, Stone::TypeError
          nil
        end
        # Use the generic Function primitive for equality (pointer comparison, not structural)
        result = Stone::Type::GENERIC_FUNCTION if result&.function?
        result || type_from_llvm_value(llvm_value)
      end

      private def type_from_llvm_value(llvm_value)
        return Stone::Type::GENERIC_FUNCTION if llvm_function?(llvm_value)

        case llvm_value.type.kind
        when :integer then llvm_value.type.width == 1 ? Stone::Type::Bool : Stone::Type::Int
        else Stone::Type::Null
        end
      end

      # Resolve the RTTI type tag, using Null for null pointers at runtime
      private def resolve_type_tag(builder, mod, stone_type, llvm_value)
        declared_tag = Stone::RTTI.type_constant_for(mod, stone_type)
        return declared_tag unless llvm_value.type.kind == :pointer

        null_tag = Stone::RTTI.type_constant_for(mod, Stone::Type::Null)
        is_null = builder.icmp(:eq, llvm_value, LLVM::Type.ptr.null, "is_null")
        builder.select(is_null, null_tag, declared_tag, "type_tag")
      end

      private def box_value(builder, llvm_value)
        box_type = llvm_function?(llvm_value) ? LLVM::Type.pointer : llvm_value.type
        alloca = builder.alloca(box_type, "eq_box")
        builder.store(llvm_value, alloca)
        alloca
      end

      # LLVM::Function values have type kind :function, not :pointer or :integer,
      # so they need special handling in type inference and boxing.
      private def llvm_function?(llvm_value)
        llvm_value.is_a?(LLVM::Function)
      end

      private def equality_operator?
        %w[== != ≠ equals?].include?(function_name)
      end

      private def chained_comparison?
        comparison_operator? && arguments.length > 2
      end

      private def comparison_operator?
        %w[< <= ≤ > >= ≥].include?(function_name)
      end

      private def boolean_operator?
        %w[∧ ∨ ⊻ ¬].include?(function_name)
      end

      private def chained_boolean?
        boolean_operator? && arguments.length > 2
      end

      private def generate_chained_boolean(builder, mod, scope)
        # Generate inline code for chained boolean operations
        # ∧(a, b, c) generates: (a && b) && c
        func = lookup_and_validate_function(mod)
        args = evaluate_arguments(builder, mod, scope)
        build_chained_boolean_op(builder, func, args)
      end

      private def lookup_and_validate_function(mod)
        func = mod.lookup_function(function_name)
        fail Stone::ReferenceError, "undefined function: #{function_name}" unless func

        func
      end

      private def build_chained_boolean_op(builder, func, args)
        # Compute first pair using the function
        result = builder.call(func, args[0], args[1], "bool_0")

        # Chain remaining operands left-to-right: (a ⊻ b) ⊻ c
        # This produces: ((a op b) op c) op d ...
        # NOT overlapping pairs like: (a op b) and (b op c)
        remaining_args = args[2..]
        remaining_args.each_with_index do |arg, i|
          result = chain_with_next_operand(builder, result, arg, i + 1)
        end

        result
      end

      private def chain_with_next_operand(builder, current_result, next_arg, index)
        # NOTE: NOT (¬) is unary and never reaches this code path
        # because chained_boolean? requires arguments.length > 2
        case function_name
        when "∧"
          builder.and(current_result, next_arg, "and_#{index}")
        when "∨"
          builder.or(current_result, next_arg, "or_#{index}")
        when "⊻"
          builder.xor(current_result, next_arg, "xor_#{index}")
        else
          fail "Unsupported boolean operator for chaining: #{function_name}"
        end
      end

      private def generate_chained_comparison(builder, mod, scope)
        # Generate inline code for chained comparisons
        # <(a, b, c) generates: (a < b) && (b < c)
        func = lookup_and_validate_function(mod)
        args = evaluate_arguments(builder, mod, scope)
        build_comparison_conjunction(builder, func, args)
      end

      private def build_comparison_conjunction(builder, func, args)
        result = builder.call(func, args[0], args[1], "cmp_0")

        (1...args.length - 1).each do |i|
          pair_result = builder.call(func, args[i], args[i + 1], "cmp_#{i}")
          result = builder.and(result, pair_result, "and_#{i}")
        end

        result
      end

      private def validate_argument_count(expected)
        return if arguments.length == expected

        fail Stone::ArgumentError, "wrong number of arguments for #{function_name} (given #{arguments.length}, expected #{expected})"
      end

      private def evaluate_arguments(builder, mod, scope)
        arguments.map { |arg| arg.to_llir(builder, mod, scope) }
      end

      private def instantiate_record(builder, mod, scope)
        record_instantiation = Stone::AST::RecordInstantiation.new(function_name, arguments)
        record_instantiation.to_llir(builder, mod, scope)
      end

      private def instantiate_generic_type(builder, mod, scope)
        specialized = specialize_generic_type(mod)
        mod.register_record_type(specialized.assigned_name, specialized)
        register_in_type_registry(specialized.assigned_name, specialized, mod, scope)
        specialized.to_llir(builder, mod, scope)
      end

      # Build a specialized RecordDefinition by substituting type arguments into the generic template.
      # Public because TopFunction also calls this during type pre-registration.
      def specialize_generic_type(mod)
        validate_type_arguments
        generic_type = mod.generic_types[function_name]
        type_arg_names = arguments.map(&:identifier)
        generic_type.specialize(type_arg_names)
      end

      private def validate_type_arguments
        invalid = arguments.reject { |arg| arg.is_a?(Stone::AST::Reference) }
        return if invalid.empty?

        fail Stone::TypeError, "generic type arguments must be type names, got: #{invalid.map(&:to_s).join(', ')}"
      end

      private def register_in_type_registry(name, record_def, mod, scope)
        type = Stone::Type.record(name:, fields: record_def.fields, llvm_type: record_def.llvm_type(mod, scope))
        Stone::Type::Registry.register(type)
      end

    end
  end
end
