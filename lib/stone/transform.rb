require "stone/ast"
require "stone/ast/integer_literal"
require "stone/ast/program_unit"
require "stone/error/overflow"
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
      token = node.children.first
      Stone::AST::IntegerLiteral.parse(token.text, token.start_location)
    end

  end
end
