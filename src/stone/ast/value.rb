require "stone/ast/error"


module Stone

  module AST

    class Value < Base

      attr_reader :value

      def initialize(slice_or_string)
        @source_location = get_source_location(slice_or_string)
        @value = slice_or_string.to_s
        normalize!
      end

      def evaluate(_context)
        self
      end

      def to_s
        "#{type}(#{value})"
      end

      def normalize!
      end

    end

  end

end


require "stone/ast/boolean"
require "stone/ast/integer"
require "stone/ast/rational"
require "stone/ast/text"

require "stone/ast/object"
