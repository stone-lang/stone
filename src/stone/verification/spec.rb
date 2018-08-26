require "stone/verification/failure"


module Stone

  module Verification

    class Spec

      attr_reader :code_block

      def initialize(code_block)
        @code_block = code_block
      end

      def run
        if expected.start_with?("#=")
          check_for_expected_result(expected.sub(/\A#=\s+/, ""))
        elsif expected.start_with?("#!")
          check_for_expected_exception(expected.sub(/\A#!\s+/, ""))
        else
          fail "Didn't find a recognizable expected result in code block:\n#{code}"
        end
      end

    private

      def check_for_expected_result(expected_result)
        if result == expected_result
          code
        else
          Failure.new(code, expected_result, result)
        end
      end

      def check_for_expected_exception(expected_exception)
        # TODO: Should also make sure the `stone eval` command exited with a non-0 status code.
        if result == expected_exception
          code
        else
          Failure.new(code, expected_exception, result)
        end
      end

      def lines
        @lines ||= code_block.split("\n")
      end

      def expected
        lines.last
      end

      def code
        lines[0..-2].join("\n")
      end

      def result
        # TODO: Escape any single quotes or backslashes in the code.
        @result ||= %x[echo '#{code}' | bin/stone eval -].chomp
      end

    end

  end

end
