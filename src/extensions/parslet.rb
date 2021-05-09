module ParsletExtensions

  # Make all methods available as class methods as well as instance methods.
  def self.included(base)
    base.extend(self)
  end

  # A rule that outputs an AST node.
  def rule!(name, opts = {}, &definition)
    rule(name, opts) { self.instance_eval(&definition).as(name) }
  end

  def parens(exp)
    str("(").ignore >> exp >> str(")").ignore
  end

  def curly_braces(exp)
    str("{").ignore >> exp >> str("}").ignore
  end

  def square_brackets(exp)
    str("[").ignore >> exp >> str("]").ignore
  end

end
