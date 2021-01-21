require "parslet"

require "stone/cli/command"


module Stone
  module CLI

    class Parse < Stone::CLI::Command

      desc "Output the parse tree"
      argument :source_files, type: :array, required: true, desc: "Source files"
      option :markdown, type: :boolean, default: false

      def call(source_files:, markdown:, **_args)
        each_input_file(source_files, markdown: markdown) do |input|
          puts language.parse(input)
        rescue Parslet::ParseFailed => e
          puts e.parse_failure_cause.ascii_tree
          exit 1
        end
      end

    end

    register "parse", Parse

  end
end
