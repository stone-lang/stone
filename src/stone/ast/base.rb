module Stone

  module AST

    class Base

      def evaluate(_context)
        fail NotImplementedError
      end

      def type
        fail NotImplementedError
      end

      def to_s
        fail NotImplementedError
      end

      def error?(children)
        [children].flatten.find{ |child| child.is_a?(Error) }
      end

    end

  end

end


require "stone/ast/comment"
require "stone/ast/value"
require "stone/ast/operation"
require "stone/ast/function_call"
require "stone/ast/function"
require "stone/ast/assignment"
require "stone/ast/variable_reference"
