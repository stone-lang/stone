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
        specs_in_file(file).map(&:value).map{ |code| run_spec(code) }
      end

      def run_spec(code)
        Stone::Verification::Spec.new(code).run.tap { |result| print_result(result) }
      end

      def specs_in_file(file)
        markdown = Kramdown::Document.new(File.read(file))
        markdown.root.children.select{ |e| e.type == :codeblock && e.options[:lang] == "stone" }
      end

      def print_result(result)
        if result.success?
          print "."
        else
          print "F"
        end
      end

      def print_results
        puts
        print_failures
        puts "#{results.size} tests: #{successes.size} passed, #{failures.size} failed"
      end

      def print_failures
        failures.each do |failure|
          puts failure.code
          puts "    Expected: #{failure.expected}"
          puts "    Actual:   #{failure.actual}"
        end
      end

      def failures
        @failures ||= results.reject(&:success?)
      end

      def successes
        @successes ||= results.select(&:success?)
      end

    end

  end

end
