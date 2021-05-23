# Load all the sub-languages.
Dir[File.join(__dir__, "language", "*.rb")].each do |file|
  require file
end

require "extensions/class"


module Stone
  module Language

    # Determine the highest-level language (it'll have the most ancestors).
    DEFAULT = Language::Base.descendants.max_by { |lang| lang.ancestors.size }

  end
end
