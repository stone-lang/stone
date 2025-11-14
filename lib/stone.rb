# Load extensions
Dir[File.join(__dir__, "extensions", "*.rb")].each do
  require_relative it
end

require "llvm/core"
require "llvm/execution_engine"

require "grammy/scanner"
require "stone/error"
require "stone/error/overflow"
require "stone/grammar"
require "stone/transform"
require "stone/ast"
require "stone/ast/integer_literal"
require "stone/ast/program_unit"


module Stone

  def self.parse(input)
    Stone::Grammar.parse(input)
  end

  def self.transform(parse_tree)
    transformer = Stone::Transform.new
    transformer.transform(parse_tree)
  end

  # Returns an AST
  def self.compile(input)
    parse_tree = parse(input)
    transform(parse_tree)
  end

  def self.eval(input)
    ast = compile(input)
    ast.eval
  end

end
