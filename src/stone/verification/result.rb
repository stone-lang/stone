module Stone

  module Verification

    class Result

      attr_reader :code, :expected, :actual, :error, :expecting_error, :success

      def initialize(code, expected, actual, error = nil, expecting_error: false)
        @code = code
        @expected = expected
        @actual = actual
        @error = error
        @expecting_error = expecting_error
      end

      def success?
        if expecting_error
          @success = (expected == error)
        elsif error
          @success = false
        else
          @success = (expected == actual)
        end
      end

      def failed?
        !success?
      end

    end

  end

end
