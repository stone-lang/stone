module Stone

  module Verification

    class Result

      attr_reader :code, :expected, :actual, :exception, :expecting_exception

      def initialize(code, expected, actual, exception = nil, expecting_exception: false)
        @code = code
        @expected = expected
        @actual = actual
        @exception = exception
        @expecting_exception = expecting_exception
      end

      def success?
        if expecting_exception
          expected == exception
        else
          expected == actual
        end
      end

    end

  end

end
