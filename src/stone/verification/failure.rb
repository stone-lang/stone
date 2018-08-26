module Stone

  module Verification

    class Failure

      attr_reader :code, :expected, :actual

      def initialize(code, expected, actual)
        @code = code
        @expected = expected
        @actual = actual
      end

    end

  end

end
