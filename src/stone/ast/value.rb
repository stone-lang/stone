require "stone/ast/error"


module Stone

  module AST

    class Value < Node

      # NOTE: This should be an object of a native Ruby class.
      attr_reader :value

      def initialize(slice_or_string)
        @source_location = get_source_location(slice_or_string)
        @value = slice_or_string.to_s
        normalize!
      end

      def evaluate(_context)
        self
      end

      def to_s(untyped: false)
        if untyped
          value
        else
          "#{type}(#{value})"
        end
      end

      def normalize!
      end

      # This might return an object of a different type.
      def normalized!
        self
      end

    end

  end

end

require "stone/ast/any"
require "stone/ast/null"
require "stone/ast/boolean"
require "stone/ast/number"
require "stone/ast/text"

require "stone/ast/object"
