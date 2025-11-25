require "stone/ast"


module Stone
  class AST
    class Reference < Stone::AST

      attr_reader :identifier

      def initialize(identifier)
        @identifier = identifier
        @name = :reference
      end

      # rubocop:disable Metrics/AbcSize
      def to_llir(builder, mod)
        # Check lambda parameters first (if we're inside a lambda)
        param_storage = mod.lambda_param_storage
        return builder.load(param_storage[identifier], identifier) if param_storage && param_storage[identifier]

        # Check globals (constants, variables)
        global = mod.globals[identifier]
        return builder.load(global, identifier) if global

        # Check functions (function names are also references)
        function = mod.functions[identifier]
        return function if function

        fail Stone::ReferenceError, "undefined constant, variable, or function: #{identifier}"
      end
      # rubocop:enable Metrics/AbcSize

      def to_s
        identifier
      end

    end
  end
end
