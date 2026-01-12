require "stone/ast/expression"

# TODO: Eventually, TRUE and FALSE should be top-level constants defined as
# __BUILTIN__.Boolean.TRUE and __BUILTIN__.Boolean.FALSE rather than literals.

module Stone
  class AST
    class BooleanLiteral < Stone::AST::Expression

      TRUE = 1
      FALSE = 0

      def self.parse(text, location)
        new(text)
      rescue ex
        raise Stone::Error(ex.message, location) # TODO: Make a more specific error?
      end

      attr_reader :value

      def initialize(value)
        @name = :boolean_literal
        case value
        when "TRUE"
          @value = TRUE
        when "FALSE"
          @value = FALSE
        else
          fail "expected TRUE or FALSE"
        end
      end

      def to_llir(_builder, _mod, _scope = Stone::Scope.top_level)
        @value == TRUE ? LLVM::TRUE : LLVM::FALSE
      end

      def type(_context = nil)
        Stone::Type::Bool
      end

    end
  end
end
