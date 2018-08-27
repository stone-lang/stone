require "parslet"


module Stone

  class Transform < Parslet::Transform

    rule(literal_boolean: simple(:b)) { AST::LiteralBoolean.new(b) }
    rule(literal_integer: simple(:i)) { AST::LiteralInteger.new(i) }
    rule(literal_text: simple(:t)) { AST::LiteralText.new(t) }
    rule(unary_operation: {operator: simple(:op), operand: simple(:arg)}) { AST::UnaryOperation.new(op, arg) }
    rule(binary_operation: {operator: simple(:op), operand0: simple(:arg0), operand: simple(:arg1)}) { AST::BinaryOperation.new(op, [arg0, arg1]) }

  end

end
