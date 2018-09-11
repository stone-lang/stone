require "extensions/argf"

require "stone/parser/parser"
require "stone/parser/transform"
require "stone/verification/suite"

require "kramdown"
require "pry"


module Stone

  class CLI

    attr_reader :options

    def self.run
      new.run
    end

    def run
      subcommand = ARGV[0]
      ARGV.shift

      extract_options

      if self.respond_to?("run_#{subcommand}", true)
        __send__("run_#{subcommand}")
      else
        puts "Don't know the '#{subcommand}' subcommand."
        exit 1
      end
    end

  private

    def run_parse
      each_input_file do |input|
        puts parse(input)
      rescue Parslet::ParseFailed => e
        puts e.parse_failure_cause.ascii_tree
      end
    end

    def run_eval
      each_input_file do |input|
        top_context = {}
        puts transform(parse(input)).map{ |node|
          node.evaluate(top_context)
        }.compact
      rescue Parslet::ParseFailed => e
        puts e.parse_failure_cause.ascii_tree
      end
    end

    def run_verify
      suite = Stone::Verification::Suite.new(debug: debug_option?)
      each_input_file do |input|
        suite.run(input) do
          transform(parse(input))
        end
      rescue Parslet::ParseFailed => e
        puts e.parse_failure_cause.ascii_tree
      end
      suite.complete
    end

    def extract_options
      @options = []
      while ARGV[0] =~ /^--/
        @options << ARGV[0]
        ARGV.shift
      end
    end

    def each_input_file
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

    def markdown_code_blocks(file)
      markdown = Kramdown::Document.new(file.read)
      markdown.root.children.select{ |e| e.type == :codeblock && e.options[:lang] == "stone" }.map(&:value)
    end

    def parse(input)
      parser = Stone::Parser.new
      parser.parse(input, reporter: Parslet::ErrorReporter::Contextual.new)
    end

    def transform(parse_tree)
      transformer = Stone::Transform.new
      transformer.apply(parse_tree).compact
    end

    def markdown_option?
      options.include?("--markdown")
    end

    def debug_option?
      options.include?("--debug")
    end

  end

end
