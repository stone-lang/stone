require "parslet"

require "stone/cli/command"
require "stone/top"


module Stone
  module CLI

    class Eval < Stone::CLI::Command

      desc "Output the result of each top-level expression (non-interactive REPL)"
      argument :source_files, type: :array, required: true, desc: "Source files"
      option :markdown, type: :boolean, default: false

      def call(source_files:, markdown:, **_args)
        each_input_file(source_files, markdown: markdown) do |input|
          top_context = Stone::Top.context
          puts language.ast(input).map{ |node|
            node.evaluate(top_context)
          }.compact
        rescue Parslet::ParseFailed => e
          puts e.parse_failure_cause.ascii_tree
          exit 1
        end
      end

    end

    register "eval", Eval

  end
end