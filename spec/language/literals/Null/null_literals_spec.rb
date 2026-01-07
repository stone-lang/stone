require "stone"


# Language Specification: NULL Literal
#
# This spec serves as both executable documentation and verification
# that the Stone language correctly implements NULL literal semantics.
#
# NULL is the single value of the Null type. It represents "no value"
# and is a proper pointer type (not an integer). This enables type-safe
# recursive data structures like linked lists.
#
# NULL is represented as a null pointer in LLVM IR and returns nil to Ruby.


RSpec.describe "NULL Literals" do

  describe "basic usage" do
    it "evaluates NULL to nil" do
      expect(Stone.eval("NULL")).to be_nil
    end

    it "can be assigned to a constant" do
      code = <<~STONE
        x := NULL
        x
      STONE
      expect(Stone.eval(code)).to be_nil
    end
  end

  describe "equality" do
    it "NULL equals NULL" do
      expect(Stone.eval("NULL == NULL")).to be(true)
    end

    it "NULL != NULL is false" do
      expect(Stone.eval("NULL != NULL")).to be(false)
    end

    # NULL is a pointer type, integers are i64 - different types cannot be equal
    it "NULL does not equal an integer" do
      expect(Stone.eval("NULL == 42")).to be(false)
    end

    it "integer does not equal NULL" do
      expect(Stone.eval("42 == NULL")).to be(false)
    end

    it "NULL != 42 is true" do
      expect(Stone.eval("NULL != 42")).to be(true)
    end

    it "0 does not equal NULL (different types: i64 vs pointer)" do
      expect(Stone.eval("0 == NULL")).to be(false)
    end
  end

end
