require "llvm/core"


module Stone
  class AST
    class ProgramUnit < Stone::AST
      class TopFunction

        def initialize(children)
          @children = children
        end

        def returns_string?
          last_child = @children&.last
          return false unless last_child
          return true if last_child.is_a?(Stone::AST::StringLiteral)
          return true if string_constant_definition?(last_child)
          !find_string_constant_value(last_child.identifier).nil? if last_child.is_a?(Stone::AST::Reference)
        end

        def string_literal_node
          last_child = @children.last
          return last_child if last_child.is_a?(Stone::AST::StringLiteral)
          return last_child.value_expression if string_constant_definition?(last_child)
          find_string_constant_value(last_child.identifier) if last_child.is_a?(Stone::AST::Reference)
        end

        def generate(mod)
          mod.functions.add("__top__", function_type) do |func|
            func.basic_blocks.append("entry").build do |builder|
              compiled = compile_children(builder, mod)
              build_return(builder, func, compiled&.last)
            end
          end
        end

        private def function_type
          if returns_string?
            # For strings, use output parameters since FFI can't handle struct returns
            LLVM::Type.function(
              [LLVM::Type.pointer(LLVM::Int64), LLVM::Type.pointer(LLVM::Int64)],
              LLVM::Type.void
            )
          else
            LLVM::Type.function([], LLVM::Type.i(64), varargs: false)
          end
        end

        private def build_return(builder, func, last_value)
          if returns_string?
            builder.store(last_value, func.params[0])
            builder.store(LLVM::Int64.from_i(string_literal_node.bytesize), func.params[1])
            builder.ret_void
          else
            builder.ret(return_value_for(builder, last_value))
          end
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
