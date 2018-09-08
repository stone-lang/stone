module Stone

  module AST

    class Base

      attr_reader :source_location # 1-based [line, column]

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

      def get_source_location(slice_or_ast_node)
        slice_or_ast_node.source_location
      rescue NoMethodError
        begin
          slice_or_ast_node.line_and_column
        rescue NoMethodError
          nil # It's not from source code; it's a generated value.
        end
      end

      def source_line
        source_location.first
      end

    end

  end

end


require "stone/ast/type"

require "stone/ast/comment"
require "stone/ast/value"
require "stone/ast/operation"
require "stone/ast/block"
require "stone/ast/function_call"
require "stone/ast/property_access"
require "stone/ast/function"
require "stone/ast/assignment"
require "stone/ast/variable_reference"
