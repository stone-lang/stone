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
        self.results += process_ast(source_code, yield).compact
      end

      def complete
        print_results
      end

    private

      def print_results
        puts
        print_failures
        puts "#{results.size} tests: #{successes.size} passed, #{failures.size} failed"
      end

      def print_failures
        return if failures.empty?
        puts "\nFailed specs:\n\n"
        failures.each do |failure|
          puts failure.code
          puts "    Expected: #{failure.expected}"
          puts "    Actual:   #{failure.actual}"
        end
        puts
      end

      def failures
        @failures ||= results.reject(&:success?)
      end

      def successes
        @successes ||= results.select(&:success?)
      end

      def process_ast(source_code, ast) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        last_comment = nil
        top_context = {}
        last_node = nil
        last_result = nil
        ast.map{ |node|
          if node.is_a?(Stone::AST::Comment)
            spec = Stone::Verification::Spec.new(code_between(source_code, node, last_comment), node, last_result)
            last_comment = node
            spec.run.tap { |result| spec.print_result(result) unless result.nil? }
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

      def code_between(source_code, comment, last_comment)
        if last_comment.nil?
          source_code.split("\n")[0..(comment.source_line - 2)].join("\n")
        else
          source_code.split("\n")[last_comment.source_line..(comment.source_line - 2)].join("\n")
        end
      end

    end

  end

end
