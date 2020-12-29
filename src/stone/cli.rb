require "extensions/argf"
require "extensions/class"

require "stone/version"
require "stone/verification/suite"
require "stone/top"
require "stone/ast/error"

# Load all the sub-languages, then determine the highest-level sub-language (it'll have the most ancestors).
Dir[File.join(__dir__, "language", "*.rb")].each { |file| require file }
DEFAULT_LANGUAGE = ::Stone::Language::Base.descendants.sort_by { |lang| lang.ancestors.size }.last

require "readline"
require "kramdown"


module Stone

  class CLI

    def self.run
      new.run
    end

    def run
      if options.include?("--version")
        puts "Stone version #{Stone::VERSION}"
        exit 0
      elsif self.respond_to?("run_#{subcommand}", true)
        __send__("run_#{subcommand}")
        exit 0
      else
        puts "Don't know the '#{subcommand}' subcommand."
        exit 1
      end
    end

    private def language
      @language ||= DEFAULT_LANGUAGE.new
      # TODO: Allow a command-line option to select a sub-language.
    end

    private def run_parse
      each_input_file do |input|
        puts language.parse(input)
      rescue Parslet::ParseFailed => e
        puts e.parse_failure_cause.ascii_tree
        exit 1
      end
    end

    private def run_eval
      each_input_file do |input|
        top_context = Stone::Top.context
        puts language.ast(input).map{ |node|
          node.evaluate(top_context)
        }.compact
      rescue Parslet::ParseFailed => e
        puts e.parse_failure_cause.ascii_tree
        exit 1
      end
    end

    private def run_repl
      puts "Stone REPL"
      while (input = Readline.readline("#> ", true))
        repl_1_line(input, top_context)
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

    private def run_verify
      suite = Stone::Verification::Suite.new(debug: debug_option?)
      each_input_file do |input|
        suite.run(input) do
          language.ast(input)
        rescue Parslet::ParseFailed => e
          suite.add_failure(input, Stone::AST::Error.new("ParseError", e.parse_failure_cause))
          []
        end
      end
      suite.complete
    end

    private def options
      return @options if @options
      @options = []
      while ARGV[0] =~ /^--/
        @options << ARGV[0]
        ARGV.shift
      end
      @options
    end

    private def subcommand
      return @subcommand if @subcommand
      options # Global options come before subcommands, so we have to look for them in ARGV first.
      @subcommand = ARGV[0]
      ARGV.shift
      @subcommand
    end

    private def each_input_file
      ARGF.each_file do |file|
        if ARGF.filename.end_with?(".md") || (ARGF.filename == "-" && markdown_option?)
          markdown_code_blocks(file).each do |code_block|
            yield code_block
          end
        else
          input = file.read
          yield input.end_with?("\n") ? input : input << "\n"
        end
      end
    end

    private def markdown_code_blocks(file)
      markdown = Kramdown::Document.new(file.read)
      markdown.root.children.select{ |e| e.type == :codeblock && e.options[:lang] == "stone" }.map(&:value)
    end

    private def parse(input)
      parser.parse(input + "\n", reporter: Parslet::ErrorReporter::Contextual.new)
    end

    private def transform(parse_tree)
      transformer = Stone::Transform.new
      ast = transformer.apply(parse_tree)
      ast.respond_to?(:compact) ? ast.compact : ast
    end

    private def markdown_option?
      options.include?("--markdown")
    end

    private def debug_option?
      options.include?("--debug")
    end

    private def top_context
      @top_context ||= Stone::Top.context
    end

  end

end
