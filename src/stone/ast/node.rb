module Stone

  module AST

    class Node

      attr_reader :source_location # 1-based [line, column]

      # Used as a factory, for when we might want to return a different type.
      def self.new!(*)
        new(*)
      end

      abstract :evaluate
      abstract :to_s

      def error?(children)
        [children].flatten.find{ |child| child.is_a?(Builtin::Error) }
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
        source_location&.first
      end

    end

  end

end


require "stone/ast/comment"
require "stone/ast/definition"
require "stone/ast/expression"
require "stone/builtin/value"
