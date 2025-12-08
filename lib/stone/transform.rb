require "stone/ast"
require "stone/ast/boolean_literal"
require "stone/ast/integer_literal"
require "stone/ast/string_literal"
require "stone/ast/reference"
require "stone/ast/function_call"
require "stone/ast/property_access"
require "stone/ast/program_unit"
require "stone/ast/constant_definition"
require "stone/ast/lambda"
require "stone/ast/block"
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
      identifier_token = node.children.first
      expression_node = node.find_child(:expression)
      value_expression = transform(expression_node)

      Stone::AST::ConstantDefinition.new(identifier_token.text, value_expression)
    end

    transform(:literal_boolean) do |node|
      token = node.children.first
      Stone::AST::BooleanLiteral.parse(token.text, token.start_location)
    end

    transform(:literal_string) do |node|
      token = node.children.first
      Stone::AST::StringLiteral.parse(token.text, token.start_location)
    end

    transform(:literal_i64) do |node|
      token = node.children.first
      Stone::AST::IntegerLiteral.parse(token.text, token.start_location)
    end

    transform(:reference) do |node|
      identifier_token = node.children.first
      Stone::AST::Reference.new(identifier_token.text)
    end

    transform(:primary) do |node|
      # primary can be: literal | reference | lambda | block | parens(expression)
      # For parenthesized expressions, find and transform the inner expression
      expression_node = node.find_child(:expression)
      if expression_node
        transform(expression_node)
      else
        # For other primary nodes (literal, reference, etc.), let default recursion handle them
        result = nil
        node.children.each do |child|
          if child.respond_to?(:name)
            result = transform(child)
            break if result
          end
        end
        result
      end
    end

    transform(:postfix_expression) do |node|
      # Grammar: primary + (argument_list | property_accessor)[0..]
      # Build up expression from left to right: primary -> func_call -> property_access -> ...
      primary_node = node.find_child(:primary)
      base = transform(primary_node)

      # Get all postfix operations (argument_list and property_accessor nodes)
      postfix_ops = node.children.select { |child|
        child.respond_to?(:name) && %i[argument_list property_accessor].include?(child.name)
      }

      # Process each postfix operation
      postfix_ops.reduce(base) do |receiver, op_node|
        if op_node.respond_to?(:name) && op_node.name == :argument_list
          # Function call: receiver(args)
          arguments = extract_expressions_from(op_node)
          # If receiver is a Reference, use its identifier as function name
          fail "Function calls on non-reference receivers not yet supported" unless receiver.is_a?(Stone::AST::Reference)
          Stone::AST::FunctionCall.new(receiver.identifier, arguments)
        elsif op_node.respond_to?(:name) && op_node.name == :property_accessor
          # Property access: receiver.property
          # The property_accessor node contains: str(".") + identifier
          # Find the identifier (it's the last Match that's not a dot)
          identifier_match = op_node.children.reverse.find { |c| c.is_a?(Grammy::Match) && c.text != "." }
          Stone::AST::PropertyAccess.new(receiver, identifier_match.text)
        else
          receiver
        end
      end
    end

    transform(:comparison_operation) do |node|
      # Desugar comparison operations to function calls:
      # - Binary: `5 < 3` → `<(5, 3)`
      # - Chained: `1 < 2 < 3` → `<(1, 2, 3)`
      postfix_expressions = node.children.select { |c| c.respond_to?(:name) && c.name == :postfix_expression }

      # All operators in a chain must be the same (e.g., all `<` or all `==`)
      operators = node.children.select { |c| c.is_a?(Grammy::Match) && c.text !~ /\s/ }
      operator_name = operators.first.text

      # Verify all operators are the same
      fail "Mixed comparison operators not allowed: use parentheses to clarify precedence" unless operators.all? { |op| op.text == operator_name }

      # Collect all operands and create varargs function call
      operands = postfix_expressions.map { |expr| transform(expr) }
      Stone::AST::FunctionCall.new(operator_name, operands)
    end

    transform(:lambda) do |node|
      parameter_list_node = node.find_child(:parameter_list)
      block_node = node.find_child(:block)
      block_body_node = block_node ? block_node.find_child(:statement_list) : nil

      parameters = extract_parameters_from(parameter_list_node)
      body_statements = block_body_node ? extract_all_statements(block_body_node) : []

      Stone::AST::Lambda.new(parameters, body_statements)
    end

    transform(:block) do |node|
      statement_list_node = node.find_child(:statement_list)
      body_statements = statement_list_node ? extract_all_statements(statement_list_node) : []

      Stone::AST::Block.new(body_statements)
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
