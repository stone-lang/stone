module Stone
  class TypeContext

    attr_reader :llvm_module

    def initialize(llvm_module = nil)
      @llvm_module = llvm_module
      @bindings = {}
    end

    def bind(name, type)
      @bindings[name] = type
    end

    def lookup(name)
      @bindings[name]
    end

    def with_llvm_module(mod)
      new_context = self.class.new(mod)
      new_context.instance_variable_set(:@bindings, @bindings.dup)
      new_context
    end

    def record_type?(name)
      return false unless @llvm_module

      @llvm_module.record_type?(name)
    end

    def record_definition(name)
      return nil unless @llvm_module

      @llvm_module.record_types&.[](name)
    end

  end
end
