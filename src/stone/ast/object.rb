module Stone

  module AST

    class Object < Value

      attr_reader :properties

    end

  end

end


require "stone/ast/list"
