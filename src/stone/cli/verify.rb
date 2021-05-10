require "parslet"

require "stone/cli/command"
require "stone/verification/suite"


module Stone
  module CLI

    class Verify < Stone::CLI::Command

      desc "Verify that results of top-level expressions match expectations in comments"
      argument :source_files, type: :array, required: true, desc: "Source files"
      option :debug, type: :boolean, default: false
      option :markdown, type: :boolean, default: false

      def call(source_files:, debug:, markdown:, **_args) # rubocop:disable Metrics/MethodLength
        suite = Stone::Verification::Suite.new(debug: debug)
        load_prelude
        each_input_file(source_files, markdown: markdown) do |input|
          suite.run(input) do
            language.ast(input)
          rescue Parslet::ParseFailed => e
            suite.add_failure(input, Stone::AST::Error.new("ParseError", e.parse_failure_cause))
            []
          end
        end
        suite.complete
      end

    end

    register "verify", Verify

  end
end
