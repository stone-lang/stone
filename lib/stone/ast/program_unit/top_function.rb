require "llvm/core"
require "stone/libc"


module Stone
  class AST
    class ProgramUnit < Stone::AST
      class TopFunction

        def initialize(children)
          @children = children
          @mod = nil
        end

        def generate(mod)
          @mod = mod
          # Pre-register types for type checking
          register_record_types(mod)
          register_function_types
          mod.functions.add("__top__", function_type) do |func|
            func.basic_blocks.append("entry").build do |builder|
              compiled = compile_children(builder, mod)
              build_return(builder, compiled&.last)
            end
          end
        end

        private def function_type
          # All values (ints, bools, strings) are returned as i64
          # Strings are null-terminated, so length doesn't need to be returned
          LLVM::Type.function([], LLVM::Type.i(64), varargs: false)
        end

        private def build_return(builder, last_value)
          builder.ret(return_value_for(builder, last_value))
        end

        private def return_value_for(builder, value)
          return LLVM::Int64.from_i(0) if value.nil?
          return builder.zext(value, LLVM::Int64.type, "bool_to_i64") if value.type.to_s == "i1"
          return builder.ptr2int(value, LLVM::Int64.type, "ptr_to_i64") if value.type.kind == :pointer

          value
        end

        private def compile_children(builder, mod)
          @children&.compact&.select { |child| child.respond_to?(:to_llir) }&.map { |child| child.to_llir(builder, mod) }
        end

        private def find_string_constant_value(name)
          @children&.find { |c| string_constant_definition?(c) && c.identifier == name }&.value_expression
        end

        private def string_constant_definition?(node)
          node.is_a?(Stone::AST::ConstantDefinition) && node.value_expression.is_a?(Stone::AST::StringLiteral)
        end

        private def register_record_types(mod)
          @children&.each do |child|
            next unless child.is_a?(Stone::AST::ConstantDefinition)

            register_record_type_definition(child, mod)
            register_record_instance_if_needed(child, mod)
          end
        end

        private def register_record_type_definition(child, mod)
          return unless child.value_expression.is_a?(Stone::AST::RecordDefinition)

          record_def = child.value_expression
          record_def.assigned_name = child.identifier
          mod.register_record_type(child.identifier, record_def)
          register_record_type_in_registry(child.identifier, record_def)
        end

        private def register_record_type_in_registry(name, record_def)
          fields = record_def.fields.map { |f| {name: f[:name], type: f[:type]} }
          type = Stone::Type.record(name:, fields:, llvm_type: record_def.llvm_type)
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
