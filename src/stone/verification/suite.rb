require "pry"
require "kramdown"
require "rainbow"

require "stone/verification/spec"


module Stone
  module Verification

    class Suite

      attr_reader :results
      attr_reader :debug

      def initialize(debug: false)
        @results = []
        @debug = debug
      end

      # FIXME: It's time for an abstraction that encapsulates a file being verified.
      #        We'll have a "fake" file (named "-") if there's no actual file. (Null Object pattern).
      def run(source_code, filename: nil)
        return if source_code.empty?
        @results += process_ast(source_code, yield, filename: filename)
      end

      def complete
        puts failed_specs
        puts totals
        exit 1 if failures.any?
      end

      # This will probably only be used to register parse errors.
      def add_failure(code, error_message)
        @results << Result.new(code, nil, error_message)
      end

      private def totals
        "#{test_count}: #{passed_count}, #{failed_count}"
      end

      private def test_count
        "#{results.size} tests"
      end

      private def passed_count
        Rainbow("#{successes.size} passed").green
      end

      private def failed_count
        Rainbow("#{failures.size} failed").red
      end

      private def failed_specs
        return "" if failures.empty?
        "\n\nFailed specs:\n#{failures.map(&:failure_details).join("\n")}"
      end

      private def failures
        @failures ||= results.compact.select(&:failed?)
      end

      private def successes
        @successes ||= results.compact.select(&:success?)
      end

      private def process_ast(source_code, ast, filename: nil) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
        r = ast.chunk_while{ |node| !special_comment?(node) }.reduce([]){ |results, (*code, special_comment)|
          # Evaluate all the code (except comments), but keep only the last result.
          actual_result = code.reject{ |node| node.is_a?(AST::Comment) }.map{ |node| node.evaluate(Top::CONTEXT) }.last
          source_code_chunk = code_between(source_code, special_comment, code&.first)
          spec = Verification::Spec.new(source_code_chunk, special_comment, actual_result, filename: filename)
          results << spec.run.tap { |result| print result unless result.nil? }
        }.compact
      rescue NoMethodError => e
        binding.pry if debug # rubocop:disable Lint/Debugger
      end

      private def spec_result(source_code, node, last_special_comment, last_result)
        code = code_between(source_code, node, last_special_comment)
        spec = Verification::Spec.new(code, node, last_result)
        spec.run.tap { |result| print result unless result.nil? }
      end

      private def special_comment?(node)
        return false unless node.is_a?(AST::Comment)
        node.to_s =~ Verification::Spec::COMMENT_WITH_EXPECTED_RESULT || node.to_s =~ Verification::Spec::COMMENT_WITH_EXPECTED_ERROR
      end

      private def code_between(source_code, comment, last_special_comment) # rubocop:disable Metrics/AbcSize
        if last_special_comment.nil? || !last_special_comment.respond_to?(:source_line) || last_special_comment.source_line.nil?
          source_code.split("\n")[0..(comment.source_line - 2)].join("\n")
        else
          source_code.split("\n")[(last_special_comment.source_line - 1)..(comment.source_line - 2)].join("\n")
        end
      end

    end

  end
end
