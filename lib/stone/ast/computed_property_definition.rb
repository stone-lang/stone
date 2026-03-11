require "stone/ast"


module Stone
  class AST
    class ComputedPropertyDefinition < Stone::AST

      attr_reader :type_name, :property_name, :lambda

      def initialize(type_name, property_name, lambda)
        @name = :computed_property_definition
        @type_name = type_name
        @property_name = property_name
        @lambda = lambda
      end

      def to_llir(builder, mod, scope = Stone::Scope.top_level)
        # Set declared param types on the lambda before generating
        apply_lambda_param_types(scope)

        # Generate the lambda function
        func = @lambda.to_llir(builder, mod, scope)

        # Register as a function alias with the name "Type@property"
        # This allows lookup via mod.lookup_function("Type@property")
        function_name = "#{@type_name}@#{@property_name}"
        mod.register_function_alias(function_name, func)

        # Return nil (computed properties are definitions, not expressions)
        nil
      end

      private def apply_lambda_param_types(scope)
        # First, check for an explicit type declaration (e.g., "Point@sum :: (Point) -> Int")
        function_name = "#{@type_name}@#{@property_name}"
        declared_type = scope.declared_type(function_name)

        if declared_type&.function?
          @lambda.declared_param_types = declared_type.param_types
          @lambda.declared_return_type = declared_type.return_type
        else
          # Infer first parameter type from the receiver type name
          receiver_type = Stone::Type::Registry.lookup(@type_name)
          @lambda.declared_param_types = [receiver_type] if receiver_type
        end
      end

    end
  end
end
