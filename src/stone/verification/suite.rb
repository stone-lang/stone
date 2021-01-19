require "stone/verification/spec"
require "kramdown"


module Stone

  module Verification

    class Suite

      attr_accessor :results
      attr_accessor :debug

      def initialize(debug: false)
        @results = []
        @debug = debug
      end

      def run(source_code)
        return if source_code.empty?
        self.results += process_ast(source_code, yield).compact
      end

      def complete
        puts failed_specs
        puts totals
        exit 1 if failures.any?
      end

      # This will probably only be used to register parse errors.
      def add_failure(code, error_message)
        results << Result.new(code, nil, nil, error_message)
      end

      private def totals
        "#{results.size} tests: #{successes.size} passed, #{failures.size} failed"
      end

      private def failed_specs
        return "" if failures.empty?
        "\n\nFailed specs:\n#{failures.map(&:failure_details).join("\n")}"
      end

      private def failures
        @failures ||= results.select(&:failed?)
      end

      private def successes
        @successes ||= results.select(&:success?)
      end

      private def process_ast(source_code, ast) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        top_context = Stone::Top.context
        last_comment = nil
        last_node = nil
        last_result = nil
        ast.map{ |node|
          if node.is_a?(Stone::AST::Comment)
            spec = Stone::Verification::Spec.new(code_between(source_code, node, last_comment), node, last_result)
            last_comment = node
            spec.run.tap { |result| print result unless result.nil? }
          else
            begin
              last_node = node
              last_result = node.evaluate(top_context)
              nil
            rescue NoMethodError => e
              binding.pry if debug # rubocop:disable Lint/Debugger
            end
          end
        }
      end

      private def code_between(source_code, comment, last_comment)
        if last_comment.nil?
          source_code.split("\n")[0..(comment.source_line - 2)].join("\n")
        else
          source_code.split("\n")[last_comment.source_line..(comment.source_line - 2)].join("\n")
        end
      end

    end

  end

end
