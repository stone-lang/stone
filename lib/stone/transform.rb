require "stone/ast"
require "stone/ast/integer_literal"
require "stone/ast/reference"
require "stone/ast/function_call"
require "stone/ast/program_unit"
require "stone/ast/constant_definition"
require "stone/ast/lambda"
require "stone/error/overflow"
require "grammy/tree/transformation"


module Stone
  class Transform
    include Grammy::Tree::Transformation

    transform(:program_unit) do |node|
      statement_list = node.find_child(:statement_list)
      transformed_children = statement_list ? extract_all_statements(statement_list) : []
      Stone::AST::ProgramUnit.new(transformed_children)
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
      expression_node = node.find_child(:expression)
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

    transform(:lambda) do |node|
      parameter_list_node = node.find_child(:parameter_list)
      block_node = node.find_child(:block)
      block_body_node = block_node ? block_node.find_child(:statement_list) : nil

      parameters = extract_parameters_from(parameter_list_node)
      body_statements = block_body_node ? extract_all_statements(block_body_node) : []

      Stone::AST::Lambda.new(parameters, body_statements)
    end

    transform(:statement) do |node|
      # statement can be comment, definition, expression, or empty - delegate to meaningful child
      child = node.find_child(:definition) || node.find_child(:expression)
      transform(child) if child
    end

    private def extract_all_statements(statement_list_node)
      statements = []
      collect_statements(statement_list_node, statements)
      statements
    end

    private def extract_from_children(node)
      children = node.respond_to?(:children) ? node.children : (node if node.is_a?(Array))
      return [] unless children

      children.flat_map { |child| extract_expressions_from(child) }
    end

    private def extract_expressions_from(node)
      return [] unless node
      return [transform(node)] if expression_node?(node)

      extract_from_children(node)
    end

    private def expression_node?(node)
      node.respond_to?(:name) && node.name == :expression
    end

    private def extract_parameters_from(parameter_list_node)
      return [] unless parameter_list_node

      identifiers = []
      collect_identifiers(parameter_list_node, identifiers)
      identifiers
    end

    private def collect_identifiers(node, identifiers)
      return unless node
      return if add_token_identifier(node, identifiers)
      return if recurse_into_children(node, identifiers)

      add_match_identifier(node, identifiers)
    end

    private def add_token_identifier(node, identifiers)
      return false unless token_identifier?(node)

      identifiers << node.text
      true
    end

    private def token_identifier?(node)
      node.respond_to?(:name) && node.name == :identifier
    end

    private def recurse_into_children(node, identifiers)
      return false unless node.respond_to?(:children) && !node.children.empty?

      node.children.each do |child|
        collect_identifiers(child, identifiers)
      end
      true
    end

    private def add_match_identifier(node, identifiers)
      return if node.respond_to?(:name) # Skip ParseTree nodes without children
      return unless valid_identifier_match?(node)

      identifiers << node.to_s
    end

    private def valid_identifier_match?(node)
      node.respond_to?(:to_s) && node.to_s.match?(/^[a-zA-Z_][a-zA-Z0-9_]*$/)
    end

    private def collect_statements(node, statements)
      return unless node

      # Look for statement, definition, or expression nodes
      if node.respond_to?(:name) && %i[statement definition expression].include?(node.name)
        transformed = transform(node)
        statements << transformed if transformed
      elsif node.respond_to?(:children)
        node.children.each { |child| collect_statements(child, statements) }
      end
    end

  end
end
