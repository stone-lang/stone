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

      def run(source_code)
        return if source_code.empty?
        @results += process_ast(source_code, yield)
      end

      def complete
        puts failed_specs
        puts totals
        exit 1 if failures.any?
      end

      # This will probably only be used to register parse errors.
      def add_failure(code, error_message)
        @results << Result.new(code, nil, nil, error_message)
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

      private def process_ast(source_code, ast) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
        r = ast.chunk_while{ |node| !special_comment?(node) }.reduce([]){ |results, (*code, special_comment)|
          # Evaluate all the code (except comments), but keep only the last result.
          actual_result = code.reject{ |node| node.is_a?(AST::Comment) }.map{ |node| node.evaluate(Top::CONTEXT) }.last
          source_code_chunk = code_between(source_code, special_comment, code&.first)
          spec = Verification::Spec.new(source_code_chunk, special_comment, actual_result)
          results << spec.run.tap { |result| print result unless result.nil? }
        }.compact
      rescue NoMethodError => e
        binding.pry if debug # rubocop:disable Lint/Debugger
      end

      # private def process_ast(source_code, ast)
      #   results = []
      #   ast.each_cons(2) { |(previous_node, node)|
      #     if special_comment?(node)
      #       results
      #       x << X.new(x.verification_results << spec_result(source_code, node, x.last_special_comment, x.last_result), x.last_result, node)
      #     else
      #       x << X.new(x.verification_results, node.evaluate(Top::CONTEXT), x.last_special_comment)
      #     end
      #   }.first
      # rescue NoMethodError => e
      #   binding.pry if debug # rubocop:disable Lint/Debugger
      # end


      # private def process_ast(source_code, ast)
      #   ast.map.with_index { |node, i|
      #     # pp node
      #     next unless special_comment?(node)
      #     last_special_comment = ast[0..i-1].reverse.find{|n| special_comment?(n) }
      #     # pp last_special_comment
      #     last_code_node = ast[0..i-1].reverse.reject{|n| n.is_a?(AST::Comment) }&.first
      #     # pp "last code node: #{last_code_node}"
      #     result = last_code_node.evaluate(Top::CONTEXT)
      #     # pp "result: #{result}"
      #     code = code_between(source_code, node, last_special_comment)
      #     # pp "code: #{code}"
      #     spec = Verification::Spec.new(code, node, result)
      #     # pp "spec: #{spec}"
      #     spec.run.tap { |result| print result unless result.nil? }
      #   }.compact # TODO: Can we use `filter_map` with `with_index` to eliminate the `compact`?
      # rescue NoMethodError => e
      #   binding.pry if debug # rubocop:disable Lint/Debugger
      # end



      # X = Struct.new(:verification_results, :last_result, :last_special_comment)

      # private def process_ast(source_code, ast)
      #   ast.reduce([]) { |xs, node|
      #     if special_comment?(node)
      #       x << X.new(x.verification_results << spec_result(source_code, node, x.last_special_comment, x.last_result), x.last_result, node)
      #     else
      #       x << X.new(x.verification_results, node.evaluate(Top::CONTEXT), x.last_special_comment)
      #     end
      #   }.first
      # rescue NoMethodError => e
      #   binding.pry if debug # rubocop:disable Lint/Debugger
      # end

      # Probably the best choice of implementations:
      # private def process_ast(source_code, ast)
      #   ast.reduce([[], nil, nil]) { |(verification_results, last_result, last_special_comment), node|
      #     if special_comment?(node)
      #       [verification_results << spec_result(source_code, node, last_special_comment, last_result), last_result, node]
      #     else
      #       [verification_results, node.evaluate(Top::CONTEXT), last_special_comment]
      #     end
      #   }.first
      # rescue NoMethodError => e
      #   binding.pry if debug # rubocop:disable Lint/Debugger
      # end

      # private def process_ast(source_code, ast) # rubocop:disable Metrics/MethodLength
      #   last_special_comment = nil
      #   last_result = nil
      #   ast.map{ |node|
      #     if node.is_a?(AST::Comment)
      #       if special_comment?(node)
      #         spec = Verification::Spec.new(code_between(source_code, node, last_special_comment), node, last_result)
      #         last_special_comment = node
      #         spec.run.tap { |result| print result unless result.nil? }
      #       end
      #     else
      #       begin
      #         last_result = node.evaluate(Top::CONTEXT)
      #         nil
      #       rescue NoMethodError => e
      #         binding.pry if debug # rubocop:disable Lint/Debugger
      #       end
      #     end
      #   }
      # end

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
