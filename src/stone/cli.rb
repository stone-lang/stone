require "dry/cli"


module Stone
  module CLI

    extend Dry::CLI::Registry

    def self.run
      Dry::CLI.new(self).call
    end

  end
end


# Load all the sub-commands.
Dir[File.join(__dir__, "cli", "*.rb")].each do |file|
  require file
end
