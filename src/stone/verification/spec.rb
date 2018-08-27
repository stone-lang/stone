require "stone/verification/result"

require "tempfile"


module Stone

  module Verification

    class Spec

      attr_reader :code_block

      def initialize(code_block)
        @code_block = code_block
      end

      def run
        fail "Didn't find a recognizable expected result in code block:\n#{code}" unless expected_result || expected_exception
        Result.new(code, expected_result || expected_exception, actual_result, actual_exception, expecting_exception: expected_exception)
      end

    private

      def actual_result
        @actual_result ||= Tempfile.open("example.stone") { |file|
          file.write(code)
          file.fsync
          %x[bin/stone eval #{file.path} 2>/dev/null].chomp
        }
      end

      def actual_exception
        actual_result unless $CHILD_STATUS&.exitstatus&.zero?
      end

      def lines
        @lines ||= code_block.split("\n")
      end

      def expectation
        @expectation ||= lines.last
      end

      def expected_result
        expectation.sub(/\A#=\s+/, "") if expectation.match?(/\A#=\s+/)
      end

      def expected_exception
        expectation.sub(/\A#!\s+/, "") if expectation.match?(/\A#!\s+/)
      end

      def code
        lines[0..-2].join("\n")
      end

    end

  end

end
