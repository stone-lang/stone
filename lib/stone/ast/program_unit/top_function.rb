require "llvm/core"
require "stone/libc"
require "stone/scope"
require "stone/ast/two_phase_processing"


module Stone
  class AST
    class ProgramUnit < Stone::AST
      class TopFunction
        include TwoPhaseProcessing

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
          register_function_types
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
          # Mixed union field access now returns i64 (payload extracted directly)
          # so it does NOT return a pointer

          # String literals return pointers
          return true if node.is_a?(Stone::AST::StringLiteral)

          # References to string constants return pointers
          return true if reference_to_string_constant?(node)

          # Certain PropertyAccess patterns return string pointers
          return true if string_returning_property?(node)

          # Check Stone type system for other cases
          # Rescue errors since some types (computed properties, etc.) aren't registered yet
          stone_type = safe_get_type(node)
          return true if stone_type == Stone::Type::String

          # Record instances return pointers
          return true if stone_type&.record?

          false
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
          node.type(@mod)
        rescue Stone::PropertyError, Stone::TypeError
          # Type couldn't be determined at this stage - default to non-pointer (i64)
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

          record_def = @mod.record_types[record_type_name]
          return nil unless record_def

          annotation = record_def.field_type_annotation(property_access.property)
          return nil unless Stone::AST::FieldHelpers.union_annotation?(annotation)

          Stone::AST::FieldHelpers.resolve_field_type({type: annotation})
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

            register_record_type_definition(child, mod, scope)
            register_record_instance_if_needed(child, mod)
          end
        end

        private def register_record_type_definition(child, mod, scope)
          return unless child.value_expression.is_a?(Stone::AST::RecordDefinition)

          record_def = child.value_expression
          record_def.assigned_name = child.identifier
          mod.register_record_type(child.identifier, record_def)
          register_record_type_in_registry(child.identifier, record_def, mod, scope)
        end

        private def register_record_type_in_registry(name, record_def, mod, scope)
          fields = record_def.fields.map { |f| {name: f[:name], type: f[:type]} }
          type = Stone::Type.record(name:, fields:, llvm_type: record_def.llvm_type(mod, scope))
          Stone::Type::Registry.register(type)
        end

        private def register_record_instance_if_needed(child, mod)
          if child.value_expression.is_a?(Stone::AST::RecordInstantiation)
            record_type_name = child.value_expression.record_type_name
            mod.register_record_instance(child.identifier, record_type_name)
          elsif child.value_expression.is_a?(Stone::AST::FunctionCall) && mod.record_type?(child.value_expression.function_name)
            mod.register_record_instance(child.identifier, child.value_expression.function_name)
          end
        end

        private def register_function_types
          @children&.each do |child|
            next unless child.is_a?(Stone::AST::ConstantDefinition)
            next unless child.value_expression.is_a?(Stone::AST::Lambda)

            func_type = child.value_expression.type
            Stone::Type::Registry.register_as(child.identifier, func_type)
          end
        end

      end
    end
  end
end
