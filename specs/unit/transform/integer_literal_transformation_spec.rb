require "stone/transform"
require "stone/grammar"

# rubocop:disable RSpec/DescribeClass
RSpec.describe "Integer Literal Transformation" do

  let(:transformer) { Stone::Transform.new }

  describe "transforming parse tree to AST" do
    it "transforms positive integer" do
      parse_tree = Stone::Grammar.parse("42")
      ast = transformer.transform(parse_tree)

      expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
      expect(ast.children.first.value).to eq(42)
    end

    it "transforms negative integer" do
      parse_tree = Stone::Grammar.parse("-17")
      ast = transformer.transform(parse_tree)

      expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
      expect(ast.children.first.value).to eq(-17)
    end

    it "transforms zero" do
      parse_tree = Stone::Grammar.parse("0")
      ast = transformer.transform(parse_tree)

      expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
      expect(ast.children.first.value).to eq(0)
    end
  end

  describe "transforming binary literals to AST" do
    it "transforms binary integer" do
      parse_tree = Stone::Grammar.parse("0b1010")
      ast = transformer.transform(parse_tree)

      expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
      expect(ast.children.first.value).to eq(10)
    end

    it "transforms negative binary integer" do
      parse_tree = Stone::Grammar.parse("-0b101")
      ast = transformer.transform(parse_tree)

      expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
      expect(ast.children.first.value).to eq(-5)
    end

    it "transforms positive signed binary integer" do
      parse_tree = Stone::Grammar.parse("+0b11")
      ast = transformer.transform(parse_tree)

      expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
      expect(ast.children.first.value).to eq(3)
    end
  end

  describe "transforming octal literals to AST" do
    it "transforms octal integer" do
      parse_tree = Stone::Grammar.parse("0o777")
      ast = transformer.transform(parse_tree)

      expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
      expect(ast.children.first.value).to eq(511)
    end

    it "transforms negative octal integer" do
      parse_tree = Stone::Grammar.parse("-0o77")
      ast = transformer.transform(parse_tree)

      expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
      expect(ast.children.first.value).to eq(-63)
    end

    it "transforms positive signed octal integer" do
      parse_tree = Stone::Grammar.parse("+0o10")
      ast = transformer.transform(parse_tree)

      expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
      expect(ast.children.first.value).to eq(8)
    end
  end

  describe "transforming hexadecimal literals to AST" do
    it "transforms hex integer" do
      parse_tree = Stone::Grammar.parse("0xff")
      ast = transformer.transform(parse_tree)

      expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
      expect(ast.children.first.value).to eq(255)
    end

    it "transforms hex integer with mixed case digits" do
      parse_tree = Stone::Grammar.parse("0xDeAdBeEf")
      ast = transformer.transform(parse_tree)

      expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
      expect(ast.children.first.value).to eq(3_735_928_559)
    end

    it "transforms negative hex integer" do
      parse_tree = Stone::Grammar.parse("-0xff")
      ast = transformer.transform(parse_tree)

      expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
      expect(ast.children.first.value).to eq(-255)
    end

    it "transforms positive signed hex integer" do
      parse_tree = Stone::Grammar.parse("+0x10")
      ast = transformer.transform(parse_tree)

      expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
      expect(ast.children.first.value).to eq(16)
    end
  end

  describe "64-bit integer range limits" do
    describe "decimal" do
      it "transforms maximum 64-bit signed integer" do
        parse_tree = Stone::Grammar.parse("9223372036854775807")
        ast = transformer.transform(parse_tree)

        expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
        expect(ast.children.first.value).to eq(9_223_372_036_854_775_807)
      end

      it "transforms minimum 64-bit signed integer" do
        parse_tree = Stone::Grammar.parse("-9223372036854775808")
        ast = transformer.transform(parse_tree)

        expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
        expect(ast.children.first.value).to eq(-9_223_372_036_854_775_808)
      end

      it "transforms near-maximum values" do
        parse_tree = Stone::Grammar.parse("9223372036854775806")
        ast = transformer.transform(parse_tree)

        expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
        expect(ast.children.first.value).to eq(9_223_372_036_854_775_806)
      end

      it "transforms near-minimum values" do
        parse_tree = Stone::Grammar.parse("-9223372036854775807")
        ast = transformer.transform(parse_tree)

        expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
        expect(ast.children.first.value).to eq(-9_223_372_036_854_775_807)
      end
    end

    describe "binary" do
      it "transforms maximum 64-bit signed value" do
        parse_tree = Stone::Grammar.parse("0b111111111111111111111111111111111111111111111111111111111111111")
        ast = transformer.transform(parse_tree)

        expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
        expect(ast.children.first.value).to eq(9_223_372_036_854_775_807)
      end

      it "transforms minimum 64-bit signed value" do
        parse_tree = Stone::Grammar.parse("-0b1000000000000000000000000000000000000000000000000000000000000000")
        ast = transformer.transform(parse_tree)

        expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
        expect(ast.children.first.value).to eq(-9_223_372_036_854_775_808)
      end

      it "transforms 32-bit boundaries" do
        parse_tree = Stone::Grammar.parse("0b11111111111111111111111111111111")
        ast = transformer.transform(parse_tree)

        expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
        expect(ast.children.first.value).to eq(4_294_967_295)
      end

      it "transforms single bit values" do
        parse_tree = Stone::Grammar.parse("0b10000000000000000000000000000000")
        ast = transformer.transform(parse_tree)

        expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
        expect(ast.children.first.value).to eq(2_147_483_648)
      end
    end

    describe "octal" do
      it "transforms maximum 64-bit signed value" do
        parse_tree = Stone::Grammar.parse("0o777777777777777777777")
        ast = transformer.transform(parse_tree)

        expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
        expect(ast.children.first.value).to eq(9_223_372_036_854_775_807)
      end

      it "transforms minimum 64-bit signed value" do
        parse_tree = Stone::Grammar.parse("-0o1000000000000000000000")
        ast = transformer.transform(parse_tree)

        expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
        expect(ast.children.first.value).to eq(-9_223_372_036_854_775_808)
      end

      it "transforms 32-bit boundaries" do
        parse_tree = Stone::Grammar.parse("0o37777777777")
        ast = transformer.transform(parse_tree)

        expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
        expect(ast.children.first.value).to eq(4_294_967_295)
      end

      it "transforms various octal powers" do
        parse_tree = Stone::Grammar.parse("0o1000")
        ast = transformer.transform(parse_tree)

        expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
        expect(ast.children.first.value).to eq(512)
      end
    end

    describe "hexadecimal" do
      it "transforms maximum 64-bit signed value" do
        parse_tree = Stone::Grammar.parse("0x7fffffffffffffff")
        ast = transformer.transform(parse_tree)

        expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
        expect(ast.children.first.value).to eq(9_223_372_036_854_775_807)
      end

      it "transforms minimum 64-bit signed value" do
        parse_tree = Stone::Grammar.parse("-0x8000000000000000")
        ast = transformer.transform(parse_tree)

        expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
        expect(ast.children.first.value).to eq(-9_223_372_036_854_775_808)
      end

      it "transforms 32-bit boundaries" do
        parse_tree = Stone::Grammar.parse("0xffffffff")
        ast = transformer.transform(parse_tree)

        expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
        expect(ast.children.first.value).to eq(4_294_967_295)
      end

      it "transforms power-of-two boundaries" do
        parse_tree = Stone::Grammar.parse("0x100000000")
        ast = transformer.transform(parse_tree)

        expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
        expect(ast.children.first.value).to eq(4_294_967_296)
      end

      it "transforms 16-bit boundaries" do
        parse_tree = Stone::Grammar.parse("0xffff")
        ast = transformer.transform(parse_tree)

        expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
        expect(ast.children.first.value).to eq(65_535)
      end

      it "transforms 8-bit boundaries" do
        parse_tree = Stone::Grammar.parse("0xff")
        ast = transformer.transform(parse_tree)

        expect(ast.children.first).to be_a(Stone::AST::IntegerLiteral)
        expect(ast.children.first.value).to eq(255)
      end
    end
  end

end
# rubocop:enable RSpec/DescribeClass
