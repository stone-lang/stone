require "stone/ast"
require "stone/ast/two_phase_processing"
require "stone/types"


module Stone
  class AST
    class Block < Stone::AST::Expression
      include TwoPhaseProcessing

      attr_reader :statements

      class << self
        attr_accessor :block_count
      end

      @block_count = 0

      def initialize(statements)
        @name = :block
        @statements = statements
        @block_id = next_block_id
      end

      def to_llir(_builder, mod, scope = Stone::Scope.top_level)
        # Check if function already exists (happens if to_llir called multiple times on same block).
        mod.functions[function_name] || create_function(mod, function_name, function_type, scope)
      end

      def to_s
        "{ #{statements.join("\n")} }"
      end

      def type(context = nil)
        last_expression = statements.reverse.find { |stmt| stmt.type(context) }
        last_expression&.type(context)
      end

      private def next_block_id
        self.class.block_count += 1
        self.class.block_count
      end

      private def function_type
        # Blocks take no parameters and return an i64.
        LLVM::Type.function([], I64)
      end

      private def function_name
        "__#{function_prefix}_#{@block_id}__"
      end

      private def function_prefix
        "block"
      end

      private def create_function(mod, function_name, function_type, scope)
        mod.functions.add(function_name, function_type).tap do |func|
          build_function_body(func, mod, scope)
        end
      end

      private def build_function_body(func, mod, scope)
        func.basic_blocks.append("entry").build do |block_builder|
          evaluate_body_and_return(block_builder, mod, scope)
        end
      end

      # Evaluate all statements in block and return value of last statement.
      def evaluate_body_and_return(builder, mod, scope)
        child_scope = scope.child
        register_type_declarations(child_scope)
        last_result = compile_statements(builder, mod, child_scope)
        builder.ret(last_result)
      end

      private def compile_statements(builder, mod, scope)
        results = other_statements.map { |stmt| stmt.to_llir(builder, mod, scope) }
        results.compact.last || LLVM::Int64.from_i(0)
      end

      private def all_statements
        @all_statements ||= Array(statements).compact
      end

    end
  end
end
