require "stone/ast/expression"
require "stone/ast/block"
require "stone/types"


module Stone
  class AST
    class Lambda < Stone::AST::Expression

      attr_reader :parameters, :block
      attr_accessor :declared_param_types, :declared_return_type

      class << self
        attr_accessor :lambda_count
      end

      @lambda_count = 0

      def initialize(parameters, statements)
        @name = :lambda
        @parameters = parameters
        @block = Block.new(statements)
        @lambda_id = next_lambda_id
        @declared_param_types = nil
        @declared_return_type = nil
      end

      def to_llir(_builder, mod, scope = Stone::Scope.top_level)
        # Check if function already exists (happens if to_llir called multiple times on same lambda).
        mod.functions[function_name] || create_function(mod, function_name, function_type, scope)
      end

      def to_s
        "λ(#{parameters.join(', ')}) { #{block.statements.join("\n")} }"
      end

      def type(context = nil)
        return_type = @declared_return_type || @block.type(context) || Stone::Type::Int
        param_types = stone_param_types
        Stone::Type.function(param_types:, return_type:)
      end

      private def next_lambda_id
        self.class.lambda_count += 1
        self.class.lambda_count
      end

      private def function_type
        LLVM::Type.function(llvm_param_types, llvm_return_type)
      end

      private def stone_param_types
        parameters.each_index.map do |i|
          @declared_param_types&.dig(i) || Stone::Type::Int
        end
      end

      private def llvm_param_types
        stone_param_types.map { |t| stone_type_to_llvm_type(t) }
      end

      private def llvm_return_type
        return stone_type_to_llvm_type(@declared_return_type) if @declared_return_type
        I64
      end

      private def stone_type_to_llvm_type(stone_type)
        return I64 unless stone_type

        # Function types don't have llvm_type set; at runtime they're pointers to LLVM functions
        return LLVM::Type.pointer if stone_type.function?

        # Generic and union types use pointer passing for uniform calling convention
        return LLVM::Type.pointer if stone_type.generic? || stone_type.union?

        stone_type.llvm_type || I64
      end

      private def function_name
        "__#{function_prefix}_#{@lambda_id}__"
      end

      private def function_prefix
        "lambda"
      end

      private def create_function(mod, function_name, function_type, scope)
        mod.functions.add(function_name, function_type).tap do |func|
          name_parameters(func)
          build_function_body(func, mod, scope)
        end
      end

      private def name_parameters(func)
        func.params.each_with_index do |param, i|
          param.name = parameters[i]
        end
      end

      private def build_function_body(func, mod, scope)
        func.basic_blocks.append("entry").build do |lambda_builder|
          args = argument_storage(func, lambda_builder)

          # Create child scope with lambda parameters for type resolution
          lambda_scope = scope.child
          bind_parameters_in_scope(lambda_scope)

          with_parameter_context(mod, args) do
            evaluate_body_and_return(lambda_builder, mod, lambda_scope)
          end
        end
      end

      # Bind lambda parameters in scope so they can be resolved as types in annotations.
      # The value :type_parameter is a placeholder - only the presence in scope matters
      # for type resolution. Runtime access uses lambda_param_storage instead.
      private def bind_parameters_in_scope(scope)
        @parameters.each do |param|
          scope.define(param, value: :type_parameter)
        end
      end

      # Store arguments on the stack so they are treated the same as local variables.
      private def argument_storage(func, builder)
        {}.tap do |storage|
          parameters.each_with_index do |param_name, i|
            # Use the actual parameter type from the function signature
            param_type = func.params[i].type
            alloca = builder.alloca(param_type, param_name)
            builder.store(func.params[i], alloca)
            storage[param_name] = alloca
          end
        end
      end

      # Temporarily set module's parameter context so Reference nodes within the block can resolve parameter names.
      private def with_parameter_context(mod, args)
        original_storage = mod.lambda_param_storage
        original_types = mod.lambda_param_stone_types
        mod.lambda_param_storage = args
        mod.lambda_param_stone_types = stone_param_types_by_name
        yield
      ensure
        mod.lambda_param_storage = original_storage
        mod.lambda_param_stone_types = original_types
      end

      private def stone_param_types_by_name
        parameters.zip(stone_param_types).to_h
      end

      # Lambda parameters use lambda_param_storage (not scope) for stack alloca loading.
      private def evaluate_body_and_return(builder, mod, scope)
        @block.evaluate_body_and_return(builder, mod, scope)
      end

    end
  end
end
