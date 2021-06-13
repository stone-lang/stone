require "parslet/rig/rspec"

require "stone/language/operators"


RSpec.describe Stone::Language::Operators do

  subject(:parser) { described_class.new.grammar.new }

  describe "operator" do

    it "does not allow alphanumeric characters" do
      expect(parser.operator).not_to parse("abc123")
    end

    it "must not start with a decimal digit" do
      expect(parser.operator).not_to parse("123")
    end

    it "must not start with a plus or minus followed by a decimal digit" do
      expect(parser.operator).not_to parse("+123")
      expect(parser.operator).not_to parse("-123")
    end

    it "must not contain any whitespace" do
      " \t\v\n\r\f".each_char do |c|
        expect(parser.operator).not_to parse("+#{c}+")
      end
      expect(parser.operator).not_to parse("+\u00a0+") # non-breaking space
      expect(parser.operator).not_to parse("+\u2009+") # thin space
      expect(parser.operator).not_to parse("+\u200b+") # zero-width space
    end

    it "must not contain any disallowed characters" do
      %[()[]{}«»#λ,.:;@^`"\\].each_char do |character|
        expect(parser.operator).not_to parse("+#{character}")
      end
    end

    it "does not allow anything that starts like a number" do
      expect(parser.operator).not_to parse("+0")
      expect(parser.operator).not_to parse("-1")
    end

    it "allows common valid operators" do
      %w(+ ++ +- += <= != ==).each do |s|
        expect(parser.operator).to parse(s)
      end
    end

    it "must not contain any control characters" do
      ("\u0000".."\u001F").each do |c|                    # C0 range
        expect(parser.operator).not_to parse("a#{c}")
      end
      expect(parser.operator).not_to parse("a\u007F")     # Delete (doesn't work well in a Range)
      ("\u007F".."\u009F").each do |c|                    # C1 range
        expect(parser.operator).not_to parse("a#{c}")
      end
    end

  end

end
