require "stone/verification/spec"
require "kramdown"


module Stone

  module Verification

    class Suite

      ALL_SPEC_FILES = Dir["docs/specs/*.md"].reject{ |f| /README/.match(f) }

      attr_reader :results

      def self.run
        new.run
      end

      def run
        run_all_specs
        print_results
      end

    private

      def run_all_specs
        @results = ALL_SPEC_FILES.flat_map{ |f| run_specs_in_file(f) }
      end

      def run_specs_in_file(file)
        specs_in_file(file).map(&:value).map{ |code| Stone::Verification::Spec.new(code).run }
      end

      def specs_in_file(file)
        markdown = Kramdown::Document.new(File.read(file))
        markdown.root.children.select{ |e| e.type == :codeblock && e.options[:lang] == "stone" }
      end

      def print_results
        puts "#{results.size} tests: #{successes.size} passed, #{failures.size} failed"
        failures.each do |failure|
          puts "Expected '#{failure.expected}' but got '#{failure.actual}' in:\n#{failure.code}"
        end
      end

      def failures
        @failures ||= results.select{ |r| r.is_a?(Failure) }
      end

      def successes
        @successes ||= results.reject{ |r| r.is_a?(Failure) }
      end

    end

  end

end
