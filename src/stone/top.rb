require "stone/builtin/function"


module Stone

  module Top

    CONTEXT = {
      TRUE: Stone::AST::Boolean.new(true),
      FALSE: Stone::AST::Boolean.new(false),
      NULL: Stone::AST::Null.new(nil),
      Class: Stone::Builtin::Function.new("Class", 0..Float::INFINITY, ->(ctxt, args){ builtin_Class(ctxt, args) }),
      List: Stone::Builtin::Function.new("List", 0..Float::INFINITY, ->(ctxt, args){ builtin_List(ctxt, args) }),
      Pair: Stone::Builtin::Function.new("Pair", 2..2, ->(ctxt, args){ builtin_Pair(ctxt, args[0], args[1]) }),
      Map: Stone::Builtin::Function.new("Map", 0..Float::INFINITY, ->(ctxt, args){ builtin_Map(ctxt, args) }),
      identity: Stone::Builtin::Function.new("identity", 1..1, ->(ctxt, args){ builtin_identity(ctxt, args) }),
      if: Stone::Builtin::Function.new("if", 2..3, ->(ctxt, args){ builtin_if("if", ctxt, args) }),
      unless: Stone::Builtin::Function.new("unless", 2..3, ->(ctxt, args){ builtin_if("unless", ctxt, args, inverted: true) }),
      min: Stone::Builtin::Function.new("min", 1..Float::INFINITY, ->(ctxt, args){ builtin_min(ctxt, args) }),
      max: Stone::Builtin::Function.new("max", 1..Float::INFINITY, ->(ctxt, args){ builtin_max(ctxt, args) }),
    }

    # TODO: We can remove these when we have classes and (default) constructors working.
    def self.builtin_List(_context, args)
      Stone::AST::List.new(args)
    end

    def self.builtin_Pair(_context, first, second)
      Stone::AST::Pair.new(first, second)
    end

    def self.builtin_Map(_context, args)
      Stone::AST::Map.new(args)
    end

    def self.builtin_identity(_context, args)
      return Stone::AST::Error.new("ArityError", "'identity' expects 1 argument, got #{args.count}") unless args.count == 1
      args.first
    end

    def self.builtin_if(name, context, args, inverted: false) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      return Stone::AST::Error.new("ArityError", "'#{name}' expects 2 or 3 arguments, got #{args.count}") unless [2, 3].include?(args.count)
      condition, consequent, alternative = args
      condition = condition.call(context) if condition.is_a?(Stone::AST::Block)
      return Stone::AST::Error.new("TypeError", "'#{name}' condition must be a Boolean") unless condition.is_a?(Stone::AST::Boolean)
      return Stone::AST::Error.new("TypeError", "'#{name}' argument 'then' must be a block") unless consequent.is_a?(Stone::AST::Block)
      return Stone::AST::Error.new("TypeError", "'#{name}' argument 'else' must be a block") unless alternative.is_a?(Stone::AST::Block) || alternative.nil?
      if inverted ? !condition.value : condition.value
        consequent.call(context)
      elsif alternative
        alternative.call(context)
      else
        Stone::AST::Null.new("")
      end
    end

    def self.builtin_min(_context, args)
      # TODO: Check types. Ensure we only have 1 List, if we have a list.
      if args.first.is_a?(Stone::AST::List)
        Stone::AST::Number.new!(args.only.value.map(&:value).min)
      else
        Stone::AST::Number.new!(args.map(&:value).min)
      end
    end

    def self.builtin_max(_context, args)
      # TODO: Check types. Ensure we only have 1 List, if we have a list.
      if args.first.is_a?(Stone::AST::List)
        Stone::AST::Number.new!(args.only.value.map(&:value).max)
      else
        Stone::AST::Number.new!(args.map(&:value).max)
      end
    end

  end

end
