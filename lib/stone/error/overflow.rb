require "stone/error"


module Stone
  class Error
    class Overflow < Stone::Error

      attr_reader :literal

      def initialize(message = nil, location:, literal:)
        @literal = literal
        message ||= "Overflow Error: #{literal} falls outside 64-bit Int range at line #{location.line}, column #{location.column}"
        super(message, location: location)
      end

    end
  end
end
