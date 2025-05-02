require "parslet/rig/rspec"

require "stone/language/properties"

# TODO: Stone::Language::Properties passes all the grammar tests now, so delete this.
class TestParser < Stone::Language::Functions
  def grammar
    Class.new(super) do |_klass|

      override rule(:expression) { subject >> (property_access | function_call).repeat }
      # I chose the word "subject", because it's not an "object", but it's a thing with properties.
      rule!(:subject) { function | variable_reference | literal | parenthetical_expression }
      rule!(:function_call) { parens(argument_list.maybe) }
      rule!(:property_access) { str(".") >> identifier.as(:property) }
      rule!(:variable_reference) { identifier }

      # override rule(:expression) { function | function_call | literal | parenthetical_expression }
      # override rule(:expression) { function | operation | function_call | literal | block | parenthetical_expression }
      rule!(:function) { lambda_operator >> parens(parameter_list) >> whitespace >> function_body }
      rule!(:parameter_list) { (parameter >> (str(",") >> whitespace >> parameter).repeat(0)).repeat(0) }
      rule!(:parameter) { identifier }
      rule(:function_body) { block }
      rule(:block) { curly_braces((whitespace | eol).repeat(0) >> block_body.as(:block) >> (whitespace | eol).repeat(0)) }
      rule(:block_body) { (statement >> (whitespace | eol).repeat(0)).repeat(1) }
      # # TODO: This should really be an expression instead of a variable reference.
      # rule!(:function_call) { identifier.as(:identifier) >> parens(argument_list.maybe) }
      # rule!(:function_call) { identifier.as(:identifier) >> parens(argument_list.maybe) }
      # rule!(:function_call) { ((identifier).as(:identifier) | expression) >> parens(argument_list.maybe) }
      rule!(:argument_list) { (argument >> (str(",") >> whitespace >> argument).repeat(0)).repeat(0) }
      rule!(:argument) { expression }
      rule(:lambda_operator) { (str("λ") | str("->")).ignore }
    end
  end
end


RSpec.describe Stone::Language::Properties do

  # subject(:parser) { described_class.new.grammar.new }
  subject(:parser) { Stone::Language::Properties.new.grammar.new }

  describe "expression" do

    it "allows strung-together property accessors on variable references" do
      expect(parser.expression).to parse("a")
      expect(parser.expression).to parse("a.b")
      expect(parser.expression).to parse("a.b.c")
    end

    # it "allows strung-together property accessors on literals" do
    #   expect(parser.expression).to parse("1.a")
    #   expect(parser.expression).to parse("1.a.b.c")
    #   expect(parser.expression).to parse("1.23.a.b.c")
    #   expect(parser.expression).to parse("1/2.a.b.c")
    #   expect(parser.expression).to parse('"a".b.c')
    # end

    it "allows strung-together property accessors on anonymous functions" do
      expect(parser.expression).to parse("λ(x) { x }")
      expect(parser.expression).to parse("(λ(x) { x })")
      expect(parser.expression).to parse("(λ(x) { x }).a")
    end

    it "allows strung-together method calls" do
      expect(parser.expression).to parse("a()")
      expect(parser.expression).to parse("a().b")
      expect(parser.expression).to parse("a().b()")
    end

    it "allows calling the result of method calls" do
      expect(parser.expression).to parse("a()()")
      expect(parser.expression).to parse("a()().b()")
      expect(parser.expression).to parse("a()().b()()")
    end

    it "allows strung-together method calls and attribute values" do
      expect(parser.expression).to parse("a.b().c().d")
    end

  end
end
