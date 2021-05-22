module Stone

  module AST

    class Literal < Expression

      def evaluate(_context)
        value
      end

      def value
        fail NotImplementedError
      end

    end

  end

end


require "stone/ast/integer"
require "stone/ast/decimal"
require "stone/ast/rational"
require "stone/ast/text"
