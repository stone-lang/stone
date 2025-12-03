require "stone"
require "stone/type/Bool"


# Language Specification: Boolean Literals
#
# This spec serves as both executable documentation and verification
# that the Stone language correctly implements Boolean literal semantics.


RSpec.describe "Boolean Literals" do

  describe "basic Boolean literals" do
    it "evaluates to their correct boolean value" do
      expect(Stone.eval("TRUE")).to be(true)
      expect(Stone.eval("FALSE")).to be(false)
    end
  end

end
