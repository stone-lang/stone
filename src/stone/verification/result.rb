require "rainbow"


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

      def to_s
        if success?
          Rainbow(".").green
        else
          Rainbow("F").red
        end
      end

      def failure_details
        return nil unless failed?
        if expected
          "#{code}\n    Expected: #{expected}\n    Actual:   #{actual || error}"
        else
          "#{code}\n    Actual:   #{actual || error}"
        end
      end

    end

  end

end
