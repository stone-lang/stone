# Load extensions
Dir[File.join(__dir__, "extensions", "*.rb")].each { require_relative _1 }

require "llvm/core"
require "llvm/execution_engine"

require "grammy/scanner"
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

  def self.compile(input)
    parse_tree = parse(input)
    ast = transform(parse_tree)
    ast
  end

  def self.eval(input)
    ast = compile(input)
    ast.eval
  end

end
