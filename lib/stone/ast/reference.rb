require "stone/ast"


module Stone
  class AST
    class Reference < Stone::AST

      attr_reader :identifier

      def initialize(identifier)
        @identifier = identifier
        @name = :reference
      end

      def to_llir(builder, mod)
        lookup_parameter(builder, mod) ||
          lookup_global(builder, mod) ||
          lookup_function(mod) ||
          fail_with_reference_error
      end

      private def lookup_parameter(builder, mod)
        param_storage = mod.lambda_param_storage
        return nil unless param_storage && param_storage[identifier]

        builder.load(param_storage[identifier], identifier)
      end

      private def lookup_global(builder, mod)
        global = mod.globals[identifier]
        return nil unless global

        builder.load(global, identifier)
      end

      private def lookup_function(mod)
        mod.lookup_function(identifier)
      end

      private def fail_with_reference_error
        fail Stone::ReferenceError, "undefined constant, variable, or function: #{identifier}"
      end

      def to_s
        identifier
      end

    end
  end
end
