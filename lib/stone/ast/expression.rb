require "stone/ast"


module Stone
  class AST
    class Expression < Stone::AST

      def type(_context = nil) = fail NotImplementedError, "#{self.class} must implement #type"

    end
  end
end
