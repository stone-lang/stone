module Stone

  module Builtin

    class Error

      attr_reader :name
      attr_reader :description

      # TODO: We should also get the source location of the error.
      def initialize(name, description = nil)
        @name = name
        @description = description
      end

      def evaluate(_context)
        self
      end

      def type
        name
      end

      def to_s
        if description
          "#{type}: #{description}"
        else
          type
        end
      end

    end

  end

end
