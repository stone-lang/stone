require "readline"
require "parslet"

require "stone/cli/command"
require "stone/top"


module Stone
  module CLI

    class REPL < Stone::CLI::Command

      desc "Accept interactive manual input, and show the result of each top-level expression"

      def call(**_args)
        load_prelude
        puts "Stone REPL"
        while (input = Readline.readline("#> ", true))
          repl_1_line(input, Stone::Top::CONTEXT)
        end
      end

      private def repl_1_line(line, context)
        ast = language.ast(line, single_line: true)
        case result = ast.evaluate(context)
        when AST::Error
          puts "#! #{result}"
        when AST::Value
          puts "#= #{result}"
        end
      rescue Parslet::ParseFailed => e
        puts e.parse_failure_cause.ascii_tree
      end

    end

    register "repl", REPL

  end
end
