module Stone

  module AST

    class Base

      def evaluate
        fail NotImplementedError
      end

      def type
        fail NotImplementedError
      end

      def to_s
        fail NotImplementedError
      end

      def error?(children)
        children.find{ |child| child.is_a?(Error) }
      end

    end

  end

end


require "stone/ast/comment"
require "stone/ast/value"
require "stone/ast/operation"