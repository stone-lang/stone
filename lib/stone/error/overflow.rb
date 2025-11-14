require "stone/error"


module Stone
  class Error
    class Overflow < Stone::Error

      attr_reader :literal, :location

      def initialize(literal, location)
        @literal = literal
        @location = location
        super(message)
      end

      def message
        "Overflow Error: #{literal} falls outside 64-bit Int range at line #{location.line}, column #{location.column}"
      end

    end
  end
end
