require "parslet/rig/rspec"

require "stone/language/base"


RSpec.describe Stone::Language::Base do

  subject(:parser) { described_class.new.grammar.new }

  describe "indentifier" do

    it "allows alphanumeric characters" do
      expect(parser.identifier).to parse("abc123")
    end

    it "must not start with a decimal digit" do
      expect(parser.identifier).not_to parse("123abc")
    end

    it "must not start with a plus or minus followed by a decimal digit" do
      expect(parser.identifier).not_to parse("+123abc")
      expect(parser.identifier).not_to parse("-123abc")
    end

    it "must not contain any whitespace" do
      " \t\v\n\r\f".each_char do |c|
        expect(parser.identifier).not_to parse("ab#{c}c")
      end
      expect(parser.identifier).not_to parse("ab\u00a0c") # non-breaking space
      expect(parser.identifier).not_to parse("ab\u2009c") # thin space
      expect(parser.identifier).not_to parse("ab\u200bc") # zero-width space
    end

    it "must not contain any disallowed characters" do
      %[()[]{}«»#λ,.:;@^`"\\].each_char do |character|
        expect(parser.identifier).not_to parse("a#{character}")
      end
    end

    it "does not allow anything that starts like a number" do
      expect(parser.identifier).not_to parse("+0")
      expect(parser.identifier).not_to parse("-1")
    end

    it "allows common valid identifiers" do
      %w[+ ++ +- += <= != ==].each do |s|
        expect(parser.identifier).to parse(s)
      end
    end

    it "must not contain any control characters" do
      ("\u0000".."\u001F").each do |c|                    # C0 range
        expect(parser.identifier).not_to parse("a#{c}")
      end
      expect(parser.identifier).not_to parse("a\u007F")   # Delete (doesn't work well in a Range)
      ("\u007F".."\u009F").each do |c|                    # C1 range
        expect(parser.identifier).not_to parse("a#{c}")
      end
    end

  end

end
