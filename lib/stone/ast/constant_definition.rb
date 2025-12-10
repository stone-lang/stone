require "stone/ast"


module Stone
  class AST
    class ConstantDefinition < Stone::AST

      attr_reader :identifier, :value_expression

      def initialize(identifier, value_expression)
        @identifier = identifier
        @value_expression = value_expression
        @name = :constant_definition
      end

      def to_llir(builder, mod)
        return register_record_type(mod) if value_expression.is_a?(Stone::AST::RecordDefinition)

        llvm_value = value_expression.to_llir(builder, mod)

        return register_function_alias(mod, llvm_value) if llvm_value.is_a?(LLVM::Function)

        mod.register_string_constant(identifier, value_expression) if value_expression.is_a?(Stone::AST::StringLiteral)
        # Check if this is a record instantiation (either direct or via FunctionCall)
        register_record_instance(mod) if record_instantiation_or_record_constructor_call?(mod)
        create_global(mod, builder, llvm_value)
      end

      private def create_global(mod, builder, llvm_value)
        global = mod.globals.add(llvm_value.type, identifier)
        global.linkage = :internal

        if literal_constant?
          initialize_as_constant(global, llvm_value)
        else
          initialize_at_runtime(global, builder, llvm_value)
        end

        nil
      end

      private def register_record_type(mod)
        mod.register_record_type(identifier, value_expression)
        nil
      end

      # Register a function (lambda) as an alias so it can be called by the constant name
      private def register_function_alias(mod, function)
        mod.register_function_alias(identifier, function)
        nil
      end

      # Use true LLVM constants, when we can
      private def initialize_as_constant(global, llvm_value)
        global.global_constant = true
        global.initializer = llvm_value
      end

      # Runtime initialization for non-constant expressions
      private def initialize_at_runtime(global, builder, llvm_value)
        global.global_constant = false # Allow runtime update
        global.initializer = llvm_value.type.null
        builder.store(llvm_value, global)
      end

      private def literal_constant?
        value_expression.is_a?(Stone::AST::IntegerLiteral) ||
          value_expression.is_a?(Stone::AST::BooleanLiteral) ||
          value_expression.is_a?(Stone::AST::StringLiteral)
      end

      private def record_instantiation?
        value_expression.is_a?(Stone::AST::RecordInstantiation)
      end

      private def record_instantiation_or_record_constructor_call?(mod)
        return true if record_instantiation?

        # Check if this is a FunctionCall to a record constructor
        return mod.record_type?(value_expression.function_name) if value_expression.is_a?(Stone::AST::FunctionCall)

        false
      end

      private def register_record_instance(mod)
        # Find the record type from the expression (it was already evaluated in to_llir)
        record_type_name = find_record_type_name(mod)
        mod.register_record_instance(identifier, record_type_name) if record_type_name
      end

      private def find_record_type_name(mod)
        # If value_expression is a RecordInstantiation, get its type
        return value_expression.record_type_name if value_expression.is_a?(Stone::AST::RecordInstantiation)

        # If it's a FunctionCall to a record constructor, get the function name
        return value_expression.function_name if value_expression.is_a?(Stone::AST::FunctionCall) && mod.record_type?(value_expression.function_name)

        nil
      end

    end
  end
end
