require "stone/verification/result"

require "tempfile"


module Stone

  module Verification

    class Spec

      COMMENT_WITH_EXPECTED_RESULT = /\A#=\s+/
      COMMENT_WITH_EXPECTED_ERROR = /\A#!\s+/

      attr_reader :code
      attr_reader :comment
      attr_reader :actual_result

      def initialize(code, comment, actual_result)
        @code = code
        @comment = comment.to_s
        @actual_result = actual_result.to_s
      end

      def run
        return nil unless expected_result || expected_error
        Result.new(code, expected_result || expected_error, actual_result, actual_error, expecting_error: expected_error)
      end

      private def actual_error
        actual_result if expected_error
      end

      private def expected_result
        comment.sub(COMMENT_WITH_EXPECTED_RESULT, "") if comment.match?(COMMENT_WITH_EXPECTED_RESULT)
      end

      private def expected_error
        comment.sub(COMMENT_WITH_EXPECTED_ERROR, "") if comment.match?(COMMENT_WITH_EXPECTED_ERROR)
      end

    end

  end

end
