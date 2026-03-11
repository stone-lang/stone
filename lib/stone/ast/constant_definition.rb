require "stone/ast/expression"
require "stone/ast/union_type_registration"


module Stone
  class AST
    class ConstantDefinition < Stone::AST::Expression
      include UnionTypeRegistration

      attr_reader :identifier, :value_expression

      def initialize(identifier, value_expression)
        @identifier = identifier
        @value_expression = value_expression
        @name = :constant_definition
      end

      def to_llir(builder, mod, scope = Stone::Scope.top_level)
        return compile_record_type(mod, builder, scope) if value_expression.is_a?(Stone::AST::RecordDefinition)
        return compile_union_type(mod, builder, scope) if value_expression.is_a?(Stone::AST::UnionExpression)
        return register_as_generic_type if generic_type_definition?

        compile_value_expression(builder, mod, scope)
      end

      private def compile_value_expression(builder, mod, scope)
        apply_lambda_param_types(scope) if value_expression.is_a?(Stone::AST::Lambda)

        llvm_value = value_expression.to_llir(builder, mod, scope)

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

      # Compile a record type definition: generate its constructor, equals fn, and RTTI constant.
      private def compile_record_type(mod, builder = nil, scope = Stone::Scope.top_level)
        value_expression.to_llir(builder, mod, scope) if builder
        nil
      end

      # Compile a non-generic union type definition (e.g., IntOption := Null | Record(value :: Int))
      private def compile_union_type(mod, builder, scope)
        union_expr = value_expression
        union_expr.assigned_name = identifier
        register_union_record_alternatives(union_expr, identifier, scope)
        compile_union_record_llir(union_expr, mod, builder, scope)
        register_union_in_registry(union_expr, identifier, scope)
        nil
      end

      private def compile_union_record_llir(union_expr, mod, builder, scope)
        union_expr.record_alternatives.each { |record_def| record_def.to_llir(builder, mod, scope) }
      end

      # Register a function (lambda) as an alias so it can be called by the constant name
      private def register_function_alias(mod, function, scope)
        register_generic_instantiation_alias(scope) if generic_instantiation?
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
        type_name = record_type_name
        return unless type_name

        mod.register_record_instance(identifier, type_name)
        scope_type = scope_type_for_instance(type_name)
        scope.declare_type(identifier, type: scope_type) if scope_type
      end

      # For instances constructed through a union type, use the union type in scope
      # (so computed property lookup can find generic base name).
      # For plain records, use the record type directly.
      private def scope_type_for_instance(record_type_name)
        return union_scope_type if union_constructor_call?

        Stone::TypeRegistry.instance.lookup(record_type_name)
      end

      private def union_scope_type
        Stone::Type::Registry.lookup(value_expression.function_name)
      end

      private def record_type_name
        return value_expression.record_type_name if value_expression.is_a?(Stone::AST::RecordInstantiation)
        return value_expression.function_name if record_constructor_call?
        return union_record_type_name if union_constructor_call?

        nil
      end

      private def record_constructor_call?
        value_expression.is_a?(Stone::AST::FunctionCall) && Stone::Type::Registry.lookup(value_expression.function_name)&.record?
      end

      private def union_constructor_call?
        value_expression.is_a?(Stone::AST::FunctionCall) && Stone::Type::Registry.lookup(value_expression.function_name)&.union?
      end

      private def union_record_type_name
        union_type = Stone::Type::Registry.lookup(value_expression.function_name)
        union_type.find_record_alternative_by_field_count(value_expression.arguments.length)&.name
      end

      private def generic_type_definition?
        return false unless value_expression.is_a?(Stone::AST::Lambda)

        body = value_expression.block.statements.last
        body.is_a?(Stone::AST::RecordDefinition) || body.is_a?(Stone::AST::UnionExpression)
      end

      private def generic_instantiation?
        value_expression.is_a?(Stone::AST::FunctionCall) && Stone::Type::Registry.lookup(value_expression.function_name)&.generic?
      end

      private def register_generic_instantiation_alias(scope)
        canonical_name = canonical_generic_name
        canonical_type = Stone::Type::Registry.lookup(canonical_name)
        return unless canonical_type && (canonical_type.record? || canonical_type.union?)

        Stone::Type::Registry.register_as(identifier, canonical_type)
        scope.declare_type(identifier, type: canonical_type) unless scope.type_declared_locally?(identifier)
      end

      private def canonical_generic_name
        type_args = value_expression.arguments.map(&:identifier)
        "#{value_expression.function_name}(#{type_args.join(', ')})"
      end

      private def register_as_generic_type
        generic = Stone::Type::Generic.new(name: identifier, template: value_expression)
        Stone::Type::Registry.register(generic)
        nil
      end

      # Set declared param types on a lambda from type declarations in scope
      private def apply_lambda_param_types(scope)
        declared_type = scope.declared_type(identifier)
        return unless declared_type&.function?

        value_expression.declared_param_types = declared_type.param_types
        value_expression.declared_return_type = declared_type.return_type
      end

    end
  end
end
