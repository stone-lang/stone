module Stone

  module Builtin

    class Value

      # NOTE: This should be an object of a native Ruby class.
      attr_reader :value

      def initialize(slice_or_string)
        @value = slice_or_string.to_s
        normalize!
      end

      def self.new!(value)
        new(value)
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


require "stone/builtin/boolean"
# require "stone/builtin/class"
require "stone/builtin/error"
require "stone/builtin/list"
require "stone/builtin/map"
require "stone/builtin/null"
require "stone/builtin/number"
require "stone/builtin/object"
require "stone/builtin/pair"
require "stone/builtin/text"
