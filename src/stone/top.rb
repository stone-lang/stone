module Stone

  module Top

    CONTEXT = {
      type: Builtin::Function.new("type", 1..1, ->(ctxt, args){ builtin_type(ctxt, args) }),
      TRUE: Builtin::Boolean.new(true),
      FALSE: Builtin::Boolean.new(false),
      NULL: Builtin::Null.new,
      List: Builtin::Function.new("List", 0..Float::INFINITY, ->(ctxt, args){ builtin_List(ctxt, args) }),
      Pair: Builtin::Function.new("Pair", 2..2, ->(ctxt, args){ builtin_Pair(ctxt, args[0], args[1]) }),
      Map: Builtin::Function.new("Map", 0..Float::INFINITY, ->(ctxt, args){ builtin_Map(ctxt, args) }),
      if: Builtin::Function.new("if", 2..3, ->(ctxt, args){ builtin_if("if", ctxt, args) }),
      unless: Builtin::Function.new("unless", 2..3, ->(ctxt, args){ builtin_if("unless", ctxt, args, inverted: true) }),
      min: Builtin::Function.new("min", 1..Float::INFINITY, ->(ctxt, args){ builtin_min(ctxt, args) }),
      max: Builtin::Function.new("max", 1..Float::INFINITY, ->(ctxt, args){ builtin_max(ctxt, args) }),
    }

    def self.builtin_type(_context, args)
      args.first.type.to_s
    end

    # TODO: We can remove these when we have classes and (default) constructors working.
    def self.builtin_List(_context, args)
      Builtin::List.new(args)
    end

    def self.builtin_Pair(_context, first, second)
      Builtin::Pair.new(first, second)
    end

    def self.builtin_Map(_context, args)
      Builtin::Map.new(args)
    end

    def self.builtin_if(name, context, args, inverted: false) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      return Builtin::Error.new("ArityError", "'#{name}' expects 2 or 3 arguments, got #{args.count}") unless [2, 3].include?(args.count)
      condition, consequent, alternative = args
      condition = condition.call(context) if condition.is_a?(AST::Block)
      return Builtin::Error.new("TypeError", "'#{name}' condition must be a Boolean") unless condition.is_a?(Builtin::Boolean)
      return Builtin::Error.new("TypeError", "'#{name}' argument 'then' must be a block") unless consequent.is_a?(AST::Block)
      return Builtin::Error.new("TypeError", "'#{name}' argument 'else' must be a block") unless alternative.is_a?(AST::Block) || alternative.nil?
      if inverted ? !condition.value : condition.value
        consequent.call(context)
      elsif alternative
        alternative.call(context)
      else
        Builtin::Null.new
      end
    end

    def self.builtin_min(_context, args)
      # TODO: Check types. Ensure we only have 1 List, if we have a list.
      if args.first.is_a?(Builtin::List)
        Builtin::Number.new!(args.only.value.map(&:value).min)
      else
        Builtin::Number.new!(args.map(&:value).min)
      end
    end

    def self.builtin_max(_context, args)
      # TODO: Check types. Ensure we only have 1 List, if we have a list.
      if args.first.is_a?(Builtin::List)
        Builtin::Number.new!(args.only.value.map(&:value).max)
      else
        Builtin::Number.new!(args.map(&:value).max)
      end
    end

  end

end
