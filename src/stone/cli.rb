require "stone/parser/parser"
require "stone/parser/transform"


module Stone

  class CLI

    def self.run
      new.run
    end

    def run
      subcommand = ARGV[0]
      ARGV.shift

      if self.respond_to?("run_#{subcommand}", true)
        send("run_#{subcommand}")
      else
        puts "Don't know the '#{subcommand}' subcommand."
        exit 1
      end
    end

  private

    def run_eval
      input = ARGF.read
      input += "\n" unless input.end_with?("\n")
      parser = Stone::Parser.new
      transform = Stone::Transform.new
      top_context = {}
      puts transform.apply(parser.parse(input)).map{ |x| x.evaluate(top_context) }.compact
    rescue Parslet::ParseFailed => e
      puts e.parse_failure_cause.ascii_tree
    end

  end

end
