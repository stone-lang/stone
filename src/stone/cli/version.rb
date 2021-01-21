require "stone/cli/command"
require "stone/version"


module Stone
  module CLI

    class Version < Stone::CLI::Command

      desc "Print version"

      def call(*)
        puts "Stone version #{Stone::VERSION}"
      end

    end

    register "version", Version, aliases: ["--version", "-v"]

  end
end
