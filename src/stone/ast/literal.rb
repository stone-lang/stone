module Stone

  module AST

    class Literal < Expression

      def evaluate(_context)
        value
      end

      abstract :value

    end

  end

end


require "stone/ast/integer"
require "stone/ast/decimal"
require "stone/ast/rational"
require "stone/ast/text"
