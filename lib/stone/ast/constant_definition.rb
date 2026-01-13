require "stone/ast/expression"


module Stone
  class AST
    class ConstantDefinition < Stone::AST::Expression

      attr_reader :identifier, :value_expression

      def initialize(identifier, value_expression)
        @identifier = identifier
        @value_expression = value_expression
        @name = :constant_definition
      end

      def to_llir(builder, mod, scope = Stone::Scope.top_level)
        return register_record_type(mod) if value_expression.is_a?(Stone::AST::RecordDefinition)

        llvm_value = value_expression.to_llir(builder, mod, scope)

        return handle_record_definition(mod, llvm_value) if value_expression.is_a?(Stone::AST::RecordDefinition)
        return register_function_alias(mod, llvm_value, scope) if llvm_value.is_a?(LLVM::Function)

        handle_value_expression(mod, scope)
        create_global(mod, builder, llvm_value, scope)
      end

      def type(_context = nil)
        # ConstantDefinition doesn't have a value itself, it defines a binding
        # Return nil to indicate this isn't an expression
        nil
      end

      private def create_global(mod, builder, llvm_value, scope)
        global = mod.globals.add(llvm_value.type, identifier)
        global.linkage = :internal

        if literal_constant?
          initialize_as_constant(global, llvm_value)
        else
          initialize_at_runtime(global, builder, llvm_value)
        end

        # Register in scope for lexical lookup
        scope.define(identifier, value: llvm_value)

        nil
      end

      private def handle_record_definition(mod, llvm_value)
        mod.register_record_type(identifier, value_expression)
        mod.register_function_alias(identifier, llvm_value)
        nil
      end

      # Register type information for expressions whose types cannot be inferred from LLVM types.
      # - Strings: LLVM value is ptr-as-i64, need explicit String type tracking
      # - Records: User-defined types, need explicit type name tracking
      # - Integers/Booleans: Types inferred from LLVM types (i64, i1), no special handling needed
      private def handle_value_expression(mod, scope)
        if value_expression.is_a?(Stone::AST::StringLiteral)
          mod.register_string_constant(identifier, value_expression)
          scope.declare_type(identifier, type: Stone::Type::String)
        end
        register_record_instance(mod, scope)
      end

      # Register a record type definition
      private def register_record_type(mod)
        mod.register_record_type(identifier, value_expression)
        nil
      end

      # Register a function (lambda) as an alias so it can be called by the constant name
      private def register_function_alias(mod, function, scope)
        mod.register_function_alias(identifier, function)
        scope.define(identifier, value: function)
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

      private def register_record_instance(mod, scope)
        type_name = record_type_name(mod)
        return unless type_name

        mod.register_record_instance(identifier, type_name)
        record_type = Stone::TypeRegistry.instance.lookup(type_name)
        scope.declare_type(identifier, type: record_type) if record_type
      end

      private def record_type_name(mod)
        return value_expression.record_type_name if value_expression.is_a?(Stone::AST::RecordInstantiation)
        return value_expression.function_name if record_constructor_call?(mod)

        nil
      end

      private def record_constructor_call?(mod)
        value_expression.is_a?(Stone::AST::FunctionCall) && mod.record_type?(value_expression.function_name)
      end

    end
  end
end
