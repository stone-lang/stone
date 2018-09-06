module Stone

  module Verification

    class Result

      attr_reader :code, :expected, :actual, :error, :expecting_error

      def initialize(code, expected, actual, error = nil, expecting_error: false)
        @code = code
        @expected = expected
        @actual = actual
        @error = error
        @expecting_error = expecting_error
      end

      def success?
        if expecting_error
          expected == error
        else
          expected == actual
        end
      end

    end

  end

end
