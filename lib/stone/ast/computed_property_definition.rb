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

      def to_llir(builder, mod)
        # Generate the lambda function
        func = @lambda.to_llir(builder, mod)

        # Register as a function alias with the name "Type@property"
        # This allows lookup via mod.lookup_function("Type@property")
        function_name = "#{@type_name}@#{@property_name}"
        mod.register_function_alias(function_name, func)

        # Return nil (computed properties are definitions, not expressions)
        nil
      end

    end
  end
end
