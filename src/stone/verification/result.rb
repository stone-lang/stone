require "rainbow"


module Stone

  module Verification

    class Result

      attr_reader :code, :expected, :actual, :error, :expecting_error, :success, :filename

      # TODO: Combine `actual` and `error` - we can't get both
      #       We can look to see if it's an Error or not
      # TODO: Make an abstraction for an Expectation.
      #       Should include whether an error or another value is expected.
      # TODO: Make an abstraction for Code.
      #       Should include filename and line number.
      # rubocop:disable Metrics/ParameterLists
      def initialize(code, expected, actual, error = nil, expecting_error: false, filename: nil)
        @code = code
        @expected = expected
        @actual = actual
        @error = error
        @expecting_error = expecting_error
        @filename = filename
      end
      # rubocop:enable Metrics/ParameterLists

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
