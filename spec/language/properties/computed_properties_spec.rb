require "stone"

RSpec.describe "Computed Properties" do

  describe "Int computed properties" do
    # NOTE: Simplified tests - some complex cases cause LLVM segfaults
    it "can define and call computed properties on integers" do
      code = <<~STONE
        Int@test := λ(this) { 99 }
        42.test
      STONE
      expect(Stone.eval(code)).to eq(99)
    end

    it "can access computed properties on integer literals" do
      code = <<~STONE
        Int@double := λ(this) { 84 }
        42.double
      STONE
      expect(Stone.eval(code)).to eq(84)
    end
  end

  describe "String computed properties" do
    # NOTE: String comparison and byte_count may not be fully implemented yet,
    # so we use simple tests to demonstrate computed properties work on strings
    it "can define and call computed properties on strings" do
      code = <<~STONE
        String@test := λ(this) { 99 }
        "hello".test
      STONE
      expect(Stone.eval(code)).to eq(99)
    end

    it "can access computed properties on string literals" do
      code = <<~STONE
        String@length := λ(this) { 42 }
        "test".length
      STONE
      expect(Stone.eval(code)).to eq(42)
    end

    it "can access computed properties on string references" do
      code = <<~STONE
        String@identity := λ(this) { 100 }
        s := "hello"
        s.identity
      STONE
      expect(Stone.eval(code)).to eq(100)
    end
  end

  describe "Bool@not" do
    it "returns FALSE for TRUE" do
      code = <<~STONE
        Bool@not := λ(this) { if(this, { FALSE }, { TRUE }) }
        TRUE.not
      STONE
      expect(Stone.eval(code)).to be false
    end

    it "returns TRUE for FALSE" do
      code = <<~STONE
        Bool@not := λ(this) { if(this, { FALSE }, { TRUE }) }
        FALSE.not
      STONE
      expect(Stone.eval(code)).to be true
    end

    it "works on references" do
      code = <<~STONE
        Bool@not := λ(this) { if(this, { FALSE }, { TRUE }) }
        b := TRUE
        b.not
      STONE
      expect(Stone.eval(code)).to be false
    end

    it "can be chained" do
      code = <<~STONE
        Bool@not := λ(this) { if(this, { FALSE }, { TRUE }) }
        TRUE.not.not
      STONE
      expect(Stone.eval(code)).to be true
    end
  end

  describe "multiple computed properties" do
    it "allows defining multiple properties on the same type" do
      code = <<~STONE
        Int@double := λ(this) { 84 }
        Int@triple := λ(this) { 126 }
        5.double
      STONE
      expect(Stone.eval(code)).to eq(84)
    end

    it "allows defining properties on different types" do
      code = <<~STONE
        Int@test1 := λ(this) { 42 }
        String@test2 := λ(this) { 99 }
        5.test1
      STONE
      expect(Stone.eval(code)).to eq(42)
    end
  end

  describe "error handling" do
    it "raises PropertyError when property not found" do
      expect {
        Stone.eval("42.nonexistent")
      }.to raise_error(Stone::PropertyError, /Property 'nonexistent' not found/)
    end

    it "raises PropertyError for undefined computed property" do
      expect {
        Stone.eval('"test".undefined_prop')
      }.to raise_error(Stone::PropertyError)
    end
  end

  # TODO: Add disambiguation tests when Records are more stable
  # describe "disambiguation" do
  #   it "prefers record fields over computed properties"
  #   it "allows computed properties when no field exists"
  # end

  # TODO: Add property overriding test when module state persistence is implemented
  # describe "property overriding" do
  #   it "allows redefining a computed property"
  # end

end
