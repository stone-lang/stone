require "llvm/core"


module Stone
  class AST
    class ProgramUnit < Stone::AST
      class TopFunction

        def initialize(children)
          @children = children
        end

        def generate(mod)
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

      end
    end
  end
end
