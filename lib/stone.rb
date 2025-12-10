# Load extensions
Dir[File.join(__dir__, "extensions", "*.rb")].each do
  require_relative it
end

require "llvm/core"
require "llvm/execution_engine"

require "extensions/llvm_module"
require "grammy/scanner"
require "stone/error"
require "stone/error/overflow"
require "stone/error/reference_error"
require "stone/error/argument_error"
require "stone/grammar"
require "stone/transform"
require "stone/ast"
require "stone/ast/integer_literal"
require "stone/ast/string_literal"
require "stone/ast/reference"
require "stone/ast/function_call"
require "stone/ast/constant_definition"
require "stone/ast/computed_property_definition"
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
    input_with_prelude = prepend_prelude(input)
    parse_tree = parse(input_with_prelude)
    transform(parse_tree)
  end

  def self.prepend_prelude(input)
    "#{prelude_code}\n#{input}"
  end

  def self.prelude_code
    @prelude_code ||= File.read(prelude_path)
  end

  def self.prelude_path
    File.expand_path("stone/prelude.stone", __dir__)
  end

  def self.eval(input)
    ast = compile(input)
    ast.eval
  end

end
