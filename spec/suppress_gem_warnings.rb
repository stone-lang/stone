# Suppress warnings from third-party gems while keeping warnings from our code
#
# This filter removes noise from gem dependencies while preserving useful warnings
# from the Stone codebase itself.

module GemWarningFilter
  # Paths to suppress warnings from
  SUPPRESSED_PATHS = [
    "vendor/bundle",                    # Bundled gems
    ".local/share/mise/installs/ruby",  # Mise-installed Ruby gems
    "bundled_gems.rb",                  # Ruby's bundled gems
  ].freeze

  class << self
    def setup
      Warning.module_eval do
        @original_warn = method(:warn)

        def self.warn(message)
          # Suppress if message contains any of the suppressed paths
          return if GemWarningFilter::SUPPRESSED_PATHS.any? { |path| message.include?(path) }

          # Show all other warnings
          @original_warn.call(message)
        end
      end
    end
  end
end

# Activate the warning filter
GemWarningFilter.setup
