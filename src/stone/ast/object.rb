module Stone

  module AST

    class Object < Value

      def properties
        {}
      end

      def methods
        {}
      end

    end

  end

end


require "stone/ast/list"
