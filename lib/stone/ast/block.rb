require "stone/ast"
require "stone/types"


module Stone
  class AST
    class Block < Stone::AST::Expression

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

      def to_llir(_builder, mod)
        # Check if function already exists (happens if to_llir called multiple times on same block).
        mod.functions[function_name] || create_function(mod, function_name, function_type)
      end

      def to_s
        "{ #{statements.join("\n")} }"
      end

      def type(_context = nil)
        # Blocks currently return Int64
        # TODO: Infer type from last statement
        Stone::Type::Int
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

      private def create_function(mod, function_name, function_type)
        mod.functions.add(function_name, function_type).tap do |func|
          build_function_body(func, mod)
        end
      end

      private def build_function_body(func, mod)
        func.basic_blocks.append("entry").build do |block_builder|
          evaluate_body_and_return(block_builder, mod)
        end
      end

      # Evaluate all statements in block and return value of last statement.
      def evaluate_body_and_return(builder, mod)
        results = Array(statements).compact.map { |stmt| stmt.to_llir(builder, mod) }
        last_result = results.compact.last || LLVM::Int64.from_i(0)
        builder.ret(last_result)
      end

    end
  end
end
