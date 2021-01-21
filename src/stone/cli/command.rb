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
              block.call(code_block)
            end
          else
            input = file.read
            block.call(input.end_with?("\n") ? input : input << "\n")
          end
        end
      end

      private def language
        @language ||= Stone::Language::DEFAULT.new
      end

      private def markdown_code_blocks(file)
        markdown = Kramdown::Document.new(file.read)
        markdown.root.children.select{ |e| e.type == :codeblock && e.options[:lang] == "stone" }.map(&:value)
      end

      private def parse(input)
        parser.parse("#{input}\n", reporter: Parslet::ErrorReporter::Contextual.new)
      end

      private def transform(parse_tree)
        transformer = Stone::Transform.new
        ast = transformer.apply(parse_tree)
        ast.respond_to?(:compact) ? ast.compact : ast
      end

    end

  end
end
