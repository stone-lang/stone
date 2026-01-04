require "stone/ast/expression"
require "stone/type/bool"

# TODO: Eventually, TRUE and FALSE should be top-level constants defined as
# __BUILTIN__.Boolean.TRUE and __BUILTIN__.Boolean.FALSE rather than literals.

module Stone
  class AST
    class BooleanLiteral < Stone::AST::Expression

      def self.parse(text, location)
        new(text)
      rescue ex
        raise Stone::Error(ex.message, location) # TODO: Make a more specific error?
      end

      attr_reader :value

      def initialize(value)
        @name = :boolean_literal
        @value = Stone::Type::Bool
        case value
        when "TRUE"
          @value = Stone::Type::Bool::TRUE
        when "FALSE"
          @value = Stone::Type::Bool::FALSE
        else
          fail "expected TRUE or FALSE"
        end
      end

      def to_llir(_builder, _mod)
        @value == Stone::Type::Bool::TRUE ? LLVM::TRUE : LLVM::FALSE
      end

      def type(_context = nil)
        Stone::TypeRegistry.instance.bool
      end

    end
  end
end
