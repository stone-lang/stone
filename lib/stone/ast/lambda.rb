require "stone/ast/expression"
require "stone/ast/block"
require "stone/types"


module Stone
  class AST
    class Lambda < Stone::AST::Expression

      attr_reader :parameters, :block

      class << self
        attr_accessor :lambda_count
      end

      @lambda_count = 0

      def initialize(parameters, statements)
        @name = :lambda
        @parameters = parameters
        @block = Block.new(statements)
        @lambda_id = next_lambda_id
      end

      def to_llir(_builder, mod)
        # Check if function already exists (happens if to_llir called multiple times on same lambda).
        mod.functions[function_name] || create_function(mod, function_name, function_type)
      end

      def to_s
        "λ(#{parameters.join(', ')}) { #{block.statements.join("\n")} }"
      end

      def type(context = nil)
        @block.type(context)
      end

      private def next_lambda_id
        self.class.lambda_count += 1
        self.class.lambda_count
      end

      private def function_type
        # For now, we assume all functions return an i64.
        LLVM::Type.function(param_types, I64)
      end

      private def param_types
        # For now, we assume all parameters are i64.
        [I64] * parameters.size
      end

      private def function_name
        "__#{function_prefix}_#{@lambda_id}__"
      end

      private def function_prefix
        "lambda"
      end

      private def create_function(mod, function_name, function_type)
        mod.functions.add(function_name, function_type).tap do |func|
          name_parameters(func)
          build_function_body(func, mod)
        end
      end

      private def name_parameters(func)
        func.params.each_with_index do |param, i|
          param.name = parameters[i]
        end
      end

      private def build_function_body(func, mod)
        func.basic_blocks.append("entry").build do |lambda_builder|
          args = argument_storage(func, lambda_builder)

          with_parameter_context(mod, args) do
            evaluate_body_and_return(lambda_builder, mod)
          end
        end
      end

      # Store arguments on the stack so they are treated the same as local variables.
      private def argument_storage(func, builder)
        {}.tap do |storage|
          parameters.each_with_index do |param_name, i|
            alloca = builder.alloca(LLVM::Int64.type, param_name)
            builder.store(func.params[i], alloca)
            storage[param_name] = alloca
          end
        end
      end

      # Temporarily set module's parameter context so Reference nodes within the block can resolve parameter names.
      private def with_parameter_context(mod, args)
        original = mod.lambda_param_storage
        mod.lambda_param_storage = args
        yield
      ensure
        mod.lambda_param_storage = original
      end

      # Evaluate all statements in block and return value of last statement.
      private def evaluate_body_and_return(builder, mod)
        @block.evaluate_body_and_return(builder, mod)
      end

    end
  end
end
