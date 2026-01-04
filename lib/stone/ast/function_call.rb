require "stone/ast/expression"
require "stone/libc"
require "stone/error/argument_error"


module Stone
  class AST
    class FunctionCall < Stone::AST::Expression

      attr_reader :function_name, :arguments

      def initialize(function_name, arguments)
        @function_name = function_name
        @arguments = arguments
        @name = :function_call
      end

      def to_llir(builder, mod)
        # TODO: Record equality should be delegated to the type system.
        # When the type system is refactored, equality should be polymorphic:
        # - Global `==` checks that both args are the same type
        # - If same type, delegate to type-specific comparison
        # - This special case should be removed
        return generate_record_equality(builder, mod) if record_equality_comparison?(mod)
        # TODO: Record instantiation should not be special-cased here.
        # When the type system is refactored, record constructors should be
        # regular functions, and this check should be removed.
        return instantiate_record(builder, mod) if mod.record_type?(function_name)

        # For chained comparisons, generate inline comparison logic
        return generate_chained_comparison(builder, mod) if chained_comparison?

        # Regular function call
        generate_function_call(builder, mod)
      end

      def to_s
        "#{function_name}(#{arguments.join(', ')})"
      end

      def type(context = nil)
        if comparison_operator?
          Stone::Type::Bool
        elsif context&.record_type?(function_name)
          # Look up from registry if available, otherwise return name for backward compat
          Stone::Type::Registry.lookup(function_name) || function_name
        else
          Stone::Type::Int
        end
      end

      private def generate_function_call(builder, mod)
        func = mod.lookup_function(function_name)
        fail Stone::ReferenceError, "undefined function: #{function_name}" unless func

        validate_argument_count(func.function_type.argument_types.size)
        args = evaluate_arguments(builder, mod)
        builder.call(func, *args, "#{function_name}_result")
      end

      private def chained_comparison?
        comparison_operator? && arguments.length > 2
      end

      private def comparison_operator?
        %w[== != ≠ < <= ≤ > >= ≥].include?(function_name)
      end

      private def generate_chained_comparison(builder, mod)
        # Generate inline code for chained comparisons
        # <(a, b, c) generates: (a < b) && (b < c)
        func = lookup_comparison_function(mod)
        args = evaluate_arguments(builder, mod)
        build_chained_and(builder, func, args)
      end

      private def lookup_comparison_function(mod)
        func = mod.lookup_function(function_name)
        fail Stone::ReferenceError, "undefined function: #{function_name}" unless func

        func
      end

      private def build_chained_and(builder, func, args)
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

      private def evaluate_arguments(builder, mod)
        arguments.map { |arg| arg.to_llir(builder, mod) }
      end

      private def record_equality_comparison?(mod)
        return false unless equality_operator?
        return false unless arguments.size == 2

        both_arguments_are_records?(mod)
      end

      private def both_arguments_are_records?(mod)
        Stone::AST::RecordHelpers.record_instance?(arguments[0], mod) &&
          Stone::AST::RecordHelpers.record_instance?(arguments[1], mod)
      end

      private def instantiate_record(builder, mod)
        record_instantiation = Stone::AST::RecordInstantiation.new(function_name, arguments)
        record_instantiation.to_llir(builder, mod)
      end

      private def equality_operator?
        %w[== != ≠].include?(function_name)
      end

      private def generate_record_equality(builder, mod)
        records = evaluate_record_arguments(builder, mod)
        type1, type2 = get_record_types(mod)

        return different_types_result if type1 != type2

        result = compare_all_fields(builder, records, mod.record_types[type1], mod)
        apply_not_operator(builder, result)
      end

      private def evaluate_record_arguments(builder, mod)
        [arguments[0].to_llir(builder, mod), arguments[1].to_llir(builder, mod)]
      end

      private def get_record_types(mod)
        [mod.record_instance_type(arguments[0].identifier), mod.record_instance_type(arguments[1].identifier)]
      end

      private def different_types_result
        function_name == "==" ? LLVM::Int1.from_i(0) : LLVM::Int1.from_i(1)
      end

      private def apply_not_operator(builder, result)
        function_name == "==" ? result : builder.not(result, "not_equal")
      end

      private def compare_all_fields(builder, records, record_def, mod)
        fields = record_def.fields
        result = compare_fields_at_index(builder, records, fields, mod, 0)

        (1...fields.size).each do |i|
          field_equal = compare_fields_at_index(builder, records, fields, mod, i)
          result = builder.and(result, field_equal, "and_#{i}")
        end

        result
      end

      private def compare_fields_at_index(builder, records, fields, mod, index)
        field = fields[index]
        val1 = builder.extract_value(records[0], index, "field1_#{field[:name]}")
        val2 = builder.extract_value(records[1], index, "field2_#{field[:name]}")

        compare_field_values(builder, val1, val2, field[:type], mod)
      end

      private def compare_field_values(builder, val1, val2, type_name, mod)
        case type_name
        when "Int", "Bool"
          builder.icmp(:eq, val1, val2, "field_eq")
        when "String"
          # Stone represents strings as i64 pointers to null-terminated C strings
          # We need to compare the string contents, not just the pointers
          compare_strings(builder, val1, val2, mod)
        else
          fail "Unknown type for comparison: #{type_name}"
        end
      end

      private def compare_strings(builder, str_ptr1, str_ptr2, mod)
        # Optimization: check if pointers are equal first
        # If pointers differ, we still need strcmp for content comparison
        ptrs_equal = builder.icmp(:eq, str_ptr1, str_ptr2, "ptrs_eq")

        # Convert i64 pointers back to i8* for strcmp
        ptr1 = builder.int2ptr(str_ptr1, LLVM::Type.pointer(LLVM::Int8), "ptr1")
        ptr2 = builder.int2ptr(str_ptr2, LLVM::Type.pointer(LLVM::Int8), "ptr2")

        # Declare or get strcmp function
        strcmp_func = Stone::LibC.get_or_declare_strcmp(mod)
        strcmp_result = builder.call(strcmp_func, ptr1, ptr2, "strcmp_result")

        # strcmp returns 0 if strings are equal
        strings_equal = builder.icmp(:eq, strcmp_result, LLVM::Int32.from_i(0), "strings_eq")

        # Return true if pointers are equal OR string contents are equal
        # Note: This always calls strcmp, but LLVM's optimizer will likely eliminate
        # the strcmp call when ptrs_equal is true at compile time
        builder.or(ptrs_equal, strings_equal, "str_cmp_result")
      end

    end
  end
end
