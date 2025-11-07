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

    transform(:expression) { |node|
      transform(node.children.first)
    }

    transform(:literal) { |node|
      transform(node.children.first)
    }

    transform(:literal_i64) { |node|
      match = node.children.first
      value = match.text.to_i
      Stone::AST::IntegerLiteral.new(value)
    }

  end
end
