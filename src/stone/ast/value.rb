require "stone/ast/error"


module Stone

  module AST

    class Value < Base

      attr_reader :value

      def initialize(parslet_slice)
        @value = parslet_slice.to_s
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
require "stone/ast/text"
