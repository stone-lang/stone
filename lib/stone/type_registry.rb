require "singleton"


module Stone
  class TypeRegistry
    include Singleton

    def initialize
      @types = {}
    end

    def register(type)
      @types[type.name] = type
      type
    end

    def register_as(name, type)
      @types[name] = type
      type
    end

    def lookup(name)
      @types[name]
    end
    alias [] lookup

    def registered?(name)
      @types.key?(name)
    end

    def record?(name)
      type = @types[name]
      return false unless type

      !type.primitive?
    end

    def all
      @types.values
    end

    def primitives
      @types.values.select(&:primitive?)
    end

    def records
      @types.values.reject(&:primitive?)
    end

    # Convenience accessors for built-in types
    def int
      @types["Int"]
    end

    def bool
      @types["Bool"]
    end

    def string
      @types["String"]
    end

    def type
      @types["Type"]
    end

    # Reset registry (useful for testing)
    def reset!
      @types.clear
    end

  end
end
