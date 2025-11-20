require "stone/ast"
require "stone/ast/integer_literal"
require "stone/ast/reference"
require "stone/ast/function_call"
require "stone/ast/program_unit"
require "stone/ast/constant_definition"
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

    transform(:statement) do |node|
      # Find the definition or expression within the statement.
      meaningful_child = node.children.find { |child|
        child.respond_to?(:name) && %i[definition expression].include?(child.name)
      }
      transform(meaningful_child) if meaningful_child
    end

    transform(:definition) do |node|
      identifier = node.children.first.text
      expression_node = node.children.find { |child| child.respond_to?(:name) && child.name == :expression }
      value_expression = transform(expression_node)

      Stone::AST::ConstantDefinition.new(identifier, value_expression)
    end

    transform(:literal_i64) do |node|
      token = node.children.first
      Stone::AST::IntegerLiteral.parse(token.text, token.start_location)
    end

    transform(:reference) do |node|
      token = node.children.first
      Stone::AST::Reference.new(token.text)
    end

    transform(:function_call) do |node|
      node.children => [function, argument_list]

      function_reference = transform(function)
      function_name = function_reference.identifier
      arguments = extract_expressions_from(argument_list)

      Stone::AST::FunctionCall.new(function_name, arguments)
    end

    private def extract_expressions_from(node)
      return [] unless node
      return [transform(node)] if expression_node?(node)

      extract_from_children(node)
    end

    private def extract_from_children(node)
      children = node.respond_to?(:children) ? node.children : (node if node.is_a?(Array))
      return [] unless children

      children.flat_map { |child| extract_expressions_from(child) }
    end

    private def expression_node?(node)
      node.respond_to?(:name) && node.name == :expression
    end

  end
end
