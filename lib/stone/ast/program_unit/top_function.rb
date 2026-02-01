require "llvm/core"
require "stone/libc"
require "stone/scope"
require "stone/ast/two_phase_processing"
require "stone/ast/union_type_registration"


module Stone
  class AST
    class ProgramUnit < Stone::AST
      class TopFunction
        include TwoPhaseProcessing
        include UnionTypeRegistration

        def initialize(children)
          @children = children
          @mod = nil
        end

        def generate(mod, scope = Stone::Scope.top_level)
          @mod = mod
          @scope = scope
          register_all_types(mod, scope)
          mod.functions.add("__top__", function_type) { |func| build_function_body(func, mod, scope) }
        end

        private def register_all_types(mod, scope)
          register_type_declarations(scope)
          register_record_types(mod, scope)
          register_function_types(scope)
        end

        private def build_function_body(func, mod, scope)
          func.basic_blocks.append("entry").build do |builder|
            compiled = compile_children(builder, mod, scope)
            build_return(builder, compiled&.last)
          end
        end

        private def function_type
          # Return type is determined at compile time based on the last expression
          # - Pointers are returned as-is (CHERI-safe, no ptr2int)
          # - Integers and bools are returned as i64
          LLVM::Type.function([], compute_return_type, varargs: false)
        end

        private def compute_return_type
          last_child = other_statements.last
          return LLVM::Int64.type unless last_child

          # Check if the result will be a pointer
          return LLVM::Type.pointer if returns_pointer?(last_child)

          LLVM::Int64.type
        end

        private def returns_pointer?(node)
          heap_allocated_union_field_access?(node) ||
            node.is_a?(Stone::AST::StringLiteral) ||
            reference_to_string_constant?(node) ||
            string_returning_property?(node) ||
            returns_pointer_by_type?(node)
        end

        private def heap_allocated_union_field_access?(node)
          return false unless node.is_a?(Stone::AST::PropertyAccess)
          return false unless node.respond_to?(:union_field_access?)
          return false unless node.union_field_access?(@mod)

          union_type = get_union_type_for(node)
          union_type&.needs_runtime_type_tag?
        end

        private def returns_pointer_by_type?(node)
          stone_type = safe_get_type(node)
          stone_type == Stone::Type::String || stone_type&.record?
        end

        # PropertyAccess patterns that return string pointers
        private def string_returning_property?(node)
          return false unless node.is_a?(Stone::AST::PropertyAccess)

          property = node.property
          # Type.as_String returns a string pointer
          return true if property == "as_String"
          # FieldList.name returns a string pointer
          return true if property == "name"

          false
        end

        private def safe_get_type(node)
          node.type(Stone::TypeContext.new(@mod, scope: @scope))
        rescue Stone::PropertyError, Stone::TypeError
          nil
        end

        private def reference_to_string_constant?(node)
          return false unless node.is_a?(Stone::AST::Reference)

          # Look in children for a constant definition with this name that has a string value
          find_string_constant_value(node.identifier)&.is_a?(Stone::AST::StringLiteral)
        end

        private def mixed_union_field_access?(node)
          return false unless node.is_a?(Stone::AST::PropertyAccess)
          return false unless node.respond_to?(:union_field_access?)
          return false unless node.union_field_access?(@mod)

          union_type = get_union_type_for(node)
          union_type && !union_type.homogeneous?
        end

        private def get_union_type_for(property_access)
          record_type_name = property_access.get_record_type_name(@mod)
          return nil unless record_type_name

          record_type = Stone::Type::Registry.lookup(record_type_name)
          return nil unless record_type&.record?

          annotation = record_type.field_type_annotation(property_access.property)
          return nil unless Stone::AST::FieldHelpers.union_annotation?(annotation)

          annotation.to_type(Stone::Type::Registry)
        end

        private def build_return(builder, last_value)
          builder.ret(return_value_for(builder, last_value))
        end

        # Convert return value based on target return type.
        # - No ptr2int conversions (CHERI-safe)
        # - Integers/bools return as i64
        # - Pointers return as-is
        private def return_value_for(builder, value)
          return LLVM::Int64.from_i(0) if value.nil?
          return builder.zext(value, LLVM::Int64.type, "bool_to_i64") if value.type.to_s == "i1"

          # Pointers stay as pointers - no ptr2int
          value
        end

        private def compile_children(builder, mod, scope)
          # Type declarations already registered in generate()
          compile_statements(builder, mod, scope)
        end

        private def compile_statements(builder, mod, scope)
          other_statements.select { |child| child.respond_to?(:to_llir) }.map { |child| child.to_llir(builder, mod, scope) }
        end

        private def all_statements
          @all_statements ||= Array(@children).compact
        end

        private def find_string_constant_value(name)
          @children&.find { |c| string_constant_definition?(c) && c.identifier == name }&.value_expression
        end

        private def string_constant_definition?(node)
          node.is_a?(Stone::AST::ConstantDefinition) && node.value_expression.is_a?(Stone::AST::StringLiteral)
        end

        private def register_record_types(mod, scope)
          @children&.each do |child|
            next unless child.is_a?(Stone::AST::ConstantDefinition)

            register_record_type_definition(child, scope)
            register_union_type_definition(child, scope)
            register_generic_type_definition(child)
            register_generic_instantiation(child, scope)
            register_record_instance_if_needed(child, mod)
          end
        end

        private def register_record_type_definition(child, scope)
          return unless child.value_expression.is_a?(Stone::AST::RecordDefinition)

          record_def = child.value_expression
          record_def.assigned_name = child.identifier
          register_record_type_in_registry(child.identifier, record_def, scope)
        end

        private def register_union_type_definition(child, scope)
          return unless child.value_expression.is_a?(Stone::AST::UnionExpression)

          union_expr = child.value_expression
          union_expr.assigned_name = child.identifier
          register_union_record_alternatives(union_expr, child.identifier, scope)
          register_union_in_registry(union_expr, child.identifier, scope, generic_base_name: nil)
        end

        private def register_generic_type_definition(child)
          return unless child.value_expression.is_a?(Stone::AST::Lambda)

          lambda_node = child.value_expression
          body = lambda_node.block.statements.last
          return unless body.is_a?(Stone::AST::RecordDefinition) || body.is_a?(Stone::AST::UnionExpression)

          generic = Stone::Type::Generic.new(name: child.identifier, template: lambda_node)
          Stone::Type::Registry.register(generic)
        end

        private def register_generic_instantiation(child, scope)
          return unless child.value_expression.is_a?(Stone::AST::FunctionCall)

          func_call = child.value_expression
          return unless Stone::Type::Registry.lookup(func_call.function_name)&.generic?

          specialized = func_call.specialize_generic_type
          register_specialized_type(specialized, scope)
          register_type_alias(specialized.assigned_name, child.identifier, scope)
        end

        private def register_specialized_type(specialized, scope)
          canonical_name = specialized.assigned_name
          if specialized.is_a?(Stone::AST::UnionExpression)
            base_name = extract_generic_base_name(canonical_name)
            register_union_record_alternatives(specialized, canonical_name, scope)
            register_union_in_registry(specialized, canonical_name, scope, generic_base_name: base_name)
          else
            register_record_type_in_registry(canonical_name, specialized, scope)
          end
        end

        private def register_type_alias(canonical_name, alias_name, scope)
          canonical_type = Stone::Type::Registry.lookup(canonical_name)
          return unless canonical_type

          Stone::Type::Registry.register_as(alias_name, canonical_type)
          return if scope.type_declared_locally?(alias_name)

          scope.declare_type(alias_name, type: canonical_type)
        end

        private def register_record_instance_if_needed(child, mod)
          value = child.value_expression
          if value.is_a?(Stone::AST::RecordInstantiation)
            mod.register_record_instance(child.identifier, value.record_type_name)
          elsif record_constructor?(value)
            mod.register_record_instance(child.identifier, value.function_name)
          end
        end

        private def record_constructor?(value)
          value.is_a?(Stone::AST::FunctionCall) && Stone::Type::Registry.lookup(value.function_name)&.record?
        end

        private def register_function_types(scope)
          @children&.each do |child|
            next unless child.is_a?(Stone::AST::ConstantDefinition)
            next unless child.value_expression.is_a?(Stone::AST::Lambda)

            func_type = child.value_expression.type
            Stone::Type::Registry.register_as(child.identifier, func_type)
            scope.declare_type(child.identifier, type: func_type) unless scope.type_declared_locally?(child.identifier)
          end
        end

      end
    end
  end
end
