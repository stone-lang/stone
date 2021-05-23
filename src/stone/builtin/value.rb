require "extensions/module"


module Stone

  module Builtin

    class Value

      # NOTE: This should be an object of a native Ruby class.
      # TODO: Move this to subclasses.
      attr_reader :value

      # TODO: See if we can just make this `abstract :initializer`.
      # abstract :initializer
      overridable def initialize(slice_or_string)
        @value = slice_or_string.to_s
      end

      def self.new!(value)
        new(value)
      end

      abstract :type

      overridable def evaluate(_context)
        self
      end

      def to_s(untyped: false)
        if untyped
          value
        else
          "#{type}(#{value})"
        end
      end

      # WARNING: This might return an object of a different type.
      def normalized!
        self
      end
    end

  end

end

require "stone/builtin/any"
require "stone/builtin/null"
