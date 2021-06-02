require "dry/cli"
require "kramdown"

require "stone/language"


module Stone
  module CLI

    class Command < Dry::CLI::Command

      private def each_input_file(files, markdown: false, &block) # rubocop:disable Metrics/MethodLength
        files.each do |filename|
          file = File.open(filename) # TODO: Handle `-` and handle missing files.
          if filename.end_with?(".md") || (filename == "-" && markdown)
            markdown_code_blocks(file).each do |code_block|
              block.call(filename, code_block)
            end
          else
            input = file.read
            block.call(filename, input.end_with?("\n") ? input : input << "\n")
          end
        end
      end

      private def language
        @language ||= Language::DEFAULT.new
      end

      private def markdown_code_blocks(file)
        markdown = Kramdown::Document.new(file.read)
        markdown.root.children.select{ |e| e.type == :codeblock && e.options[:lang] == "stone" }.map(&:value)
      end

      private def parse(input)
        parser.parse("#{input}\n", reporter: Parslet::ErrorReporter::Contextual.new)
      end

      private def transform(parse_tree)
        transformer = Transform.new
        ast = transformer.apply(parse_tree)
        ast.respond_to?(:compact) ? ast.compact : ast
      end

      private def load_prelude
        language.ast(prelude).each do |node|
          node.evaluate(Top::CONTEXT)
        end
      end

      private def prelude
        File.open(prelude_file).read
      rescue Errno::ENOENT
        # BUG: If we leave this "file" (or ANY file) empty, `language.ast()` will CRASH.
        # This is because the returned AST node won't have an `each` method.
        # The solution to this is likely to expose the `top` grammar element.
        "1 + 1"
      end

      private def prelude_file
        ENV["STONE_PRELUDE"] || ""
      end

    end

  end
end
