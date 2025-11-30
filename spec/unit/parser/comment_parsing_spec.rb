require "stone/grammar"

RSpec.describe "Comment Parsing" do

  describe "end-of-line comments" do
    it "parses a comment after a simple expression" do
      expect("42 # this is a comment").to parse_as(:program_unit)
    end

    it "parses a comment after a constant definition" do
      expect("x := 42 # define x").to parse_as(:program_unit)
    end

    it "parses multiple statements with comments" do
      input = <<~STONE
        x := 1  # first constant
        y := 2  # second constant
      STONE
      expect(input).to parse_as(:program_unit)
    end

    it "parses comments with special characters" do
      expect("42 # comment with !@$%^&*()").to parse_as(:program_unit)
    end

    it "parses empty comments" do
      expect("42 #").to parse_as(:program_unit)
    end
  end

  describe "standalone comment lines" do
    it "parses a program with a leading comment" do
      input = <<~STONE
        # This is a comment
        42
      STONE
      expect(input).to parse_as(:program_unit)
    end

    it "parses multiple consecutive comment lines" do
      input = <<~STONE
        # Comment line 1
        # Comment line 2
        # Comment line 3
        42
      STONE
      expect(input).to parse_as(:program_unit)
    end
  end

  describe "comments in function calls" do
    it "parses function call with comment after" do
      expect("foo(42) # call foo").to parse_as(:program_unit)
    end
  end

  describe "comment edge cases" do
    it "treats # immediately after identifier as start of comment" do
      # x is parsed as expression, then #y := 42 is treated as a comment
      result = Stone::Grammar.parse("x#y := 42")
      # The comment should contain "y := 42"
      comment_nodes = []
      result.each do |node| comment_nodes << node if node&.to_s&.start_with?("#") end
      expect(comment_nodes).not_to be_empty
      expect(comment_nodes.first.to_s).to eq("#y := 42")
    end

    it "parses comment at end of file without newline" do
      expect("42 # comment at EOF").to parse_as(:program_unit)
    end
  end

  describe "parse tree contains comments" do
    it "includes comment node in parse tree" do
      result = Stone::Grammar.parse("42 # test comment\n")
      expect(result.to_s).to include("# test comment")
    end

    it "preserves comment text exactly including newline" do
      result = Stone::Grammar.parse("42 # this is important!\n")
      # The parse tree should contain the comment text including the newline
      comment_nodes = []
      result.each do |node| comment_nodes << node if node&.to_s&.start_with?("#") end
      expect(comment_nodes).not_to be_empty
      expect(comment_nodes.first.to_s).to eq("# this is important!\n")
    end
  end

end
