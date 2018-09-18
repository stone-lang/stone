module Stone

  module Top

    module_function

    def context
      {
        List: Stone::AST::BuiltinFunction.new("List", 0..Float::INFINITY, ->(ctxt, args){ builtin_List(ctxt, args) }),
        identity: Stone::AST::BuiltinFunction.new("identity", 1..1, ->(ctxt, args){ builtin_identity(ctxt, args) }),
        if: Stone::AST::BuiltinFunction.new("if", 2..3, ->(ctxt, args){ builtin_if(ctxt, args) }),
        min: Stone::AST::BuiltinFunction.new("min", 1..Float::INFINITY, ->(ctxt, args){ builtin_min(ctxt, args) }),
        max: Stone::AST::BuiltinFunction.new("max", 1..Float::INFINITY, ->(ctxt, args){ builtin_max(ctxt, args) }),
      }
    end

    # TODO: We can remove this when we have classes and (default) constructors working.
    def builtin_List(_context, args)
      Stone::AST::List.new(args)
    end

    def builtin_identity(_context, args)
      return Stone::AST::Error.new("ArityError", "'identity' expects 1 argument, got #{args.count}") unless args.count == 1
      args.first
    end

    def builtin_if(context, args) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      return Stone::AST::Error.new("ArityError", "'if' expects 2 or 3 arguments, got #{args.count}") unless [2, 3].include?(args.count)
      condition, consequent, alternative = args
      return Stone::AST::Error.new("TypeError", "'if' condition must be a Boolean") unless condition.is_a?(Stone::AST::Boolean)
      return Stone::AST::Error.new("TypeError", "'if' consequent ('then') must be a block") unless consequent.is_a?(Stone::AST::Block)
      return Stone::AST::Error.new("TypeError", "'if' alternative ('else') must be a block") unless alternative.is_a?(Stone::AST::Block) || alternative.nil?
      if condition.value
        consequent.call(context)
      elsif alternative
        alternative.call(context)
      end
    end

    def builtin_min(_context, args)
      # TODO: Check types. Ensure we only have 1 List, if we have a list.
      if args.first.is_a?(Stone::AST::List)
        Stone::AST::Number.new!(args.only.value.map(&:value).min)
      else
        Stone::AST::Number.new!(args.map(&:value).min)
      end
    end

    def builtin_max(_context, args)
      # TODO: Check types. Ensure we only have 1 List, if we have a list.
      if args.first.is_a?(Stone::AST::List)
        Stone::AST::Number.new!(args.only.value.map(&:value).max)
      else
        Stone::AST::Number.new!(args.map(&:value).max)
      end
    end

  end

end
