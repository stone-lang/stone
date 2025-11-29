require "stone/ast"


module Stone
  class AST
    class Lambda < Stone::AST

      attr_reader :parameters, :statements

      class << self
        attr_accessor :lambda_count
      end

      @lambda_count = 0

      def initialize(parameters, statements)
        @name = :lambda
        @parameters = parameters
        @statements = statements
        @lambda_id = next_lambda_id
      end

      def to_llir(_builder, mod)
        # For now, we assume all parameters and return type are i64
        i64 = LLVM::Int64.type
        param_types = [i64] * parameters.size
        function_type = LLVM::Type.function(param_types, i64)

        # Check if function already exists (happens if to_llir called multiple times on same lambda)
        func = mod.functions[function_name]
        func ||= create_lambda_function(mod, function_name, function_type)

        func
      end

      def to_s
        "λ(#{parameters.join(', ')}) { #{statements.join("\n")} }"
      end

      private def next_lambda_id
        self.class.lambda_count += 1
        self.class.lambda_count
      end

      private def function_name
        "__lambda_#{@lambda_id}__"
      end

      private def create_lambda_function(mod, function_name, function_type)
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
        results = Array(statements).compact.map { |stmt| stmt.to_llir(builder, mod) }
        last_result = results.compact.last || LLVM::Int64.from_i(0)
        builder.ret(last_result)
      end

    end
  end
end
