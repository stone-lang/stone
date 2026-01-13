module Stone
  class Scope
    attr_reader :parent, :definitions, :type_declarations

    def initialize(parent = nil)
      @parent = parent
      @definitions = {}
      @type_declarations = {}
    end

    def child
      Scope.new(self)
    end

    def define(name, value:, location: nil)
      @definitions[name] = {value:, location:}
    end

    def declare_type(name, type:, location: nil)
      @type_declarations[name] = {type:, location:}
    end

    def lookup(name)
      @definitions[name] || @parent&.lookup(name)
    end

    def lookup_local(name)
      @definitions[name]
    end

    def lookup_type_declaration(name)
      @type_declarations[name] || @parent&.lookup_type_declaration(name)
    end

    def defined_locally?(name)
      @definitions.key?(name)
    end

    def type_declared_locally?(name)
      @type_declarations.key?(name)
    end

    def declared_type(name)
      decl = lookup_type_declaration(name)
      decl&.dig(:type)
    end

    def type_declaration_location(name)
      decl = lookup_type_declaration(name)
      decl&.dig(:location)
    end

    # Resolve a type name to verify it exists in scope.
    # Returns the type name if found, nil otherwise.
    # Checks: built-in types, type declarations, definitions (constants).
    # Note: lookup_type_declaration and lookup already traverse parent chain.
    def lookup_type(name)
      return name if builtin_type?(name)
      return name if lookup_type_declaration(name)
      return name if lookup(name)

      nil
    end

    private def builtin_type?(name)
      %w[Int Bool String Type Null].include?(name)
    end

    def depth
      @parent ? @parent.depth + 1 : 0
    end

    def top_level?
      @parent.nil?
    end

    def self.top_level
      @top_level ||= new
    end

    def self.reset_top_level!
      @top_level = nil
    end
  end
end
