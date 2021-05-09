module Stone

  module Top

    CONTEXT = {
      type: Stone::Builtin::Function.new("type", 1..1, ->(ctxt, args){ builtin_type(ctxt, args) }),
      TRUE: Stone::Builtin::Boolean.new(true),
      FALSE: Stone::Builtin::Boolean.new(false),
      NULL: Stone::Builtin::Null.new,
      List: Stone::Builtin::Function.new("List", 0..Float::INFINITY, ->(ctxt, args){ builtin_List(ctxt, args) }),
      Pair: Stone::Builtin::Function.new("Pair", 2..2, ->(ctxt, args){ builtin_Pair(ctxt, args[0], args[1]) }),
      Map: Stone::Builtin::Function.new("Map", 0..Float::INFINITY, ->(ctxt, args){ builtin_Map(ctxt, args) }),
      identity: Stone::Builtin::Function.new("identity", 1..1, ->(ctxt, args){ builtin_identity(ctxt, args) }),
      if: Stone::Builtin::Function.new("if", 2..3, ->(ctxt, args){ builtin_if("if", ctxt, args) }),
      unless: Stone::Builtin::Function.new("unless", 2..3, ->(ctxt, args){ builtin_if("unless", ctxt, args, inverted: true) }),
      min: Stone::Builtin::Function.new("min", 1..Float::INFINITY, ->(ctxt, args){ builtin_min(ctxt, args) }),
      max: Stone::Builtin::Function.new("max", 1..Float::INFINITY, ->(ctxt, args){ builtin_max(ctxt, args) }),
    }

    def self.builtin_type(_context, args)
      args.first.type.to_s
    end

    # TODO: We can remove these when we have classes and (default) constructors working.
    def self.builtin_List(_context, args)
      Stone::Builtin::List.new(args)
    end

    def self.builtin_Pair(_context, first, second)
      Stone::Builtin::Pair.new(first, second)
    end

    def self.builtin_Map(_context, args)
      Stone::Builtin::Map.new(args)
    end

    def self.builtin_identity(_context, args)
      return Stone::Builtin::Error.new("ArityError", "'identity' expects 1 argument, got #{args.count}") unless args.count == 1
      args.first
    end

    def self.builtin_if(name, context, args, inverted: false) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      return Stone::Builtin::Error.new("ArityError", "'#{name}' expects 2 or 3 arguments, got #{args.count}") unless [2, 3].include?(args.count)
      condition, consequent, alternative = args
      condition = condition.call(context) if condition.is_a?(Stone::AST::Block)
      return Stone::Builtin::Error.new("TypeError", "'#{name}' condition must be a Boolean") unless condition.is_a?(Stone::Builtin::Boolean)
      return Stone::Builtin::Error.new("TypeError", "'#{name}' argument 'then' must be a block") unless consequent.is_a?(Stone::AST::Block)
      return Stone::Builtin::Error.new("TypeError", "'#{name}' argument 'else' must be a block") unless alternative.is_a?(Stone::AST::Block) || alternative.nil?
      if inverted ? !condition.value : condition.value
        consequent.call(context)
      elsif alternative
        alternative.call(context)
      else
        Stone::Builtin::Null.new
      end
    end

    def self.builtin_min(_context, args)
      # TODO: Check types. Ensure we only have 1 List, if we have a list.
      if args.first.is_a?(Stone::Builtin::List)
        Stone::Builtin::Number.new!(args.only.value.map(&:value).min)
      else
        Stone::Builtin::Number.new!(args.map(&:value).min)
      end
    end

    def self.builtin_max(_context, args)
      # TODO: Check types. Ensure we only have 1 List, if we have a list.
      if args.first.is_a?(Stone::Builtin::List)
        Stone::Builtin::Number.new!(args.only.value.map(&:value).max)
      else
        Stone::Builtin::Number.new!(args.map(&:value).max)
      end
    end

  end

end
