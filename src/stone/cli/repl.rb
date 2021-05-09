require "readline"
require "parslet"

require "stone/cli/command"
require "stone/top"


module Stone
  module CLI

    class REPL < Stone::CLI::Command

      desc "Accept interactive manual input, and show the result of each top-level expression"

      def call(**_args)
        puts "Stone REPL"
        while (input = Readline.readline("#> ", true))
          repl_1_line(input, Stone::Top::CONTEXT)
        end
      end

      private def repl_1_line(line, context)
        ast = language.ast(line, single_line: true)
        result = ast.evaluate(context)
        puts "#{repl_result_prefix(result)} #{result}"
      rescue Parslet::ParseFailed => e
        puts e.parse_failure_cause.ascii_tree
      end

      private def repl_result_prefix(result)
        case result
        when Builtin::Error
          "#!"
        when Builtin::Value
          "#="
        else
          "#?"
        end
      end

    end

    register "repl", REPL

  end
end
