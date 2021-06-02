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
      attr_reader :filename

      def initialize(code, comment, actual_result, filename: nil)
        @code = code
        @comment = comment.to_s
        @actual_result = actual_result.to_s
        @filename = filename
      end

      def run
        return nil unless expected_result || expected_error
        Result.new(code, expected_result || expected_error, actual_result, expecting_error: expected_error, filename: filename)
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
