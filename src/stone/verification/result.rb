require "rainbow"


module Stone

  module Verification

    class Result

      attr_reader :code, :expected, :actual, :expecting_error, :success, :filename

      # TODO: Make an abstraction for an Expectation.
      #       Should include whether an error or another value is expected.
      # TODO: Make an abstraction for Code.
      #       Should include filename and line number.
      def initialize(code, expected, actual, expecting_error: false, filename: nil)
        @code = code
        @expected = expected
        @actual = actual
        @expecting_error = expecting_error
        @filename = filename
      end

      def success?
        if !expecting_error && actual.is_a?(Builtin::Error)
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

      def failure_details # rubocop:disable Metrics/AbcSize
        return nil unless failed?
        [
          Rainbow("--------------------------------").gray,
          "In #{filename}",
          Rainbow(code).red,
          ("Expected: #{Rainbow(expected).blue}" if expected),
          "Actual:   #{Rainbow(actual || error).purple}",
          Rainbow("--------------------------------").gray,
        ].compact.join("\n")
      end

    end

  end

end
