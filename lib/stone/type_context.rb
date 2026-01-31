module Stone
  class TypeContext

    attr_reader :llvm_module, :scope

    def initialize(llvm_module = nil, scope: nil)
      @llvm_module = llvm_module
      @scope = scope
      @bindings = {}
    end

    def bind(name, type)
      @bindings[name] = type
    end

    def lookup(name)
      @bindings[name] || lookup_in_scope(name)
    end

    def with_llvm_module(mod)
      new_context = self.class.new(mod, scope: @scope)
      new_context.instance_variable_set(:@bindings, @bindings.dup)
      new_context
    end

    def record_type?(name)
      Stone::Type::Registry.lookup(name)&.record? || false
    end

    def record_type(name)
      Stone::Type::Registry.lookup(name)&.then { |t| t.record? ? t : nil }
    end

    private def lookup_in_scope(name)
      @scope&.declared_type(name)
    end

  end
end
