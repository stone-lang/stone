require "extensions/module"
require "extensions/enumerable"

require "stone/ast/base"

require "parslet"
require "extensions/parslet"


module Stone
  module Language
    class Base

      def evaluate(input, single_line: false)
        puts ast(input, single_line: single_line).map{ |node|
          node.evaluate(top_context)
        }.compact
      rescue Parslet::ParseFailed => e
        puts e.parse_failure_cause.ascii_tree
        exit 1
      end

      def compile(input)
        fail NotImplementedError
      end

      def ast(input, single_line: false)
        parse_tree = parse(input, single_line: single_line)
        transformer.apply(parse_tree)
      end

      def parse(input, single_line: false)
        if single_line
          parser.line.parse(input + "\n", reporter: Parslet::ErrorReporter::Contextual.new)
        else
          parser.parse(input + "\n", reporter: Parslet::ErrorReporter::Contextual.new)
        end
      end

      overridable def grammar
        Class.new(Parslet::Parser) do |klass|
          include ParsletExtensions

          root(:top)

          rule(:top) { line.repeat }
          rule(:line) { statement_line | blank_line }
          rule(:statement_line) { whitespace? >> statement >> whitespace? >> (eol | line_comment.present?) }
          overridable rule(:statement) { expression }
          overridable rule(:expression) { parenthetical_expression }
          rule(:parenthetical_expression) { parens(whitespace? >> expression >> whitespace?) }
          rule(:blank_line) { whitespace? >> line_comment.as(:comment).maybe >> eol }
          rule(:identifier) { match["[:alpha:]\\?_"] >> match["[:alnum:]\\?_"].repeat(0) }
          rule(:whitespace) { (block_comment | (eol.absent? >> match('\s'))).repeat(1) }
          rule(:whitespace?) { whitespace.maybe }
          rule(:eol) { str("\n") }
          rule(:eof) { any.absent? }
          rule(:line_comment) { str("#") >> (eol.absent? >> any).repeat(0) }
          rule(:block_comment) { str("/*") >> (str("*/").absent? >> any).repeat(0) >> str("*/") }
        end
      end

      overridable def transforms
        Class.new(Parslet::Transform) do |klass|

          rule(comment: simple(:c)) {
            AST::Comment.new(c)
          }

          def apply(*args)
            ast = super
            ast.respond_to?(:compact) ? ast.compact : ast
          end

        end
      end

      protected def top_context
        Stone::Top.context
      end

      private def parser
        grammar.new
      end

      private def transformer
        transforms.new
      end

    end
  end
end