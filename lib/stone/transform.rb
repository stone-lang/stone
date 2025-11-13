require "stone/ast"
require "stone/ast/integer_literal"
require "stone/ast/program_unit"
require "grammy/tree/transformation"


module Stone
  class Transform
    include Grammy::Tree::Transformation

    transform(:program_unit) do |node|
      transformed_children = node.children.map { |child| transform(child) }
      name = :program_unit
      Stone::AST::ProgramUnit.new(name, transformed_children)
    end

    transform(:expression) do |node|
      transform(node.children.first)
    end

    transform(:literal) do |node|
      transform(node.children.first)
    end

    transform(:literal_i64) do |node|
      text = node.children.first.text
      sign = text.start_with?("-") ? -1 : 1
      unsigned_text = text.sub(/^[+-]/, "")

      base = case unsigned_text
             when /^0b/ then 2
             when /^0o/ then 8
             when /^0x/ then 16
             else 10
             end

      digits = base == 10 ? unsigned_text : unsigned_text[2..]
      Stone::AST::IntegerLiteral.new(digits.to_i(base) * sign)
    end

  end
end
