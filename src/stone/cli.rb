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
      parser = Stone::Parser.new
      transform = Stone::Transform.new
      puts transform.apply(parser.parse(input))
    end

  end

end
