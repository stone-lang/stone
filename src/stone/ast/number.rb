module Stone

  module AST

    class Number < Value

      def type
        "Number"
      end

    end

  end

end


require "stone/ast/integer"
require "stone/ast/rational"
