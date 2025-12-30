require "stone/ast"
require "stone/ast/boolean_literal"
require "stone/ast/integer_literal"
require "stone/ast/string_literal"
require "stone/ast/reference"
require "stone/ast/type_reference"
require "stone/ast/type_of_expression"
require "stone/ast/function_call"
require "stone/ast/property_access"
require "stone/ast/program_unit"
require "stone/ast/constant_definition"
require "stone/ast/computed_property_definition"
require "stone/ast/lambda"
require "stone/ast/block"
require "stone/ast/record_definition"
require "stone/ast/record_instantiation"
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

      identifier_text = identifier_token.text

      if identifier_text.include?("@")
        # Computed property definition: Type@property
        type_name, property_name = identifier_text.split("@", 2)
        Stone::AST::ComputedPropertyDefinition.new(type_name, property_name, value_expression)
      else
        Stone::AST::ConstantDefinition.new(identifier_text, value_expression)
      end
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

    transform(:type_reference) do |_node|
      Stone::AST::TypeReference.new
    end

    transform(:type_of_expression) do |node|
      expression_node = node.find_child(:expression)
      inner_expression = transform(expression_node)
      Stone::AST::TypeOfExpression.new(inner_expression)
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

    transform(:record_definition) do |node|
      type_declarations = node.children.select { |c| c.respond_to?(:name) && c.name == :type_declaration }

      fields = type_declarations.map { |type_decl|
        extract_field_info(type_decl)
      }

      Stone::AST::RecordDefinition.new(fields)
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

    private def extract_field_info(type_decl)
      # type_declaration: identifier + ws! + str("::") + ws! + type_annotation
      {name: extract_field_name(type_decl), type: extract_type_name(type_decl)}
    end

    private def extract_field_name(type_decl)
      # Find the field name - it's the first Match with text (not whitespace or ::)
      type_decl.children.each do |child|
        return child.text if child.is_a?(Grammy::Match) && child.text && !child.text.strip.empty? && child.text != "::"
      end
      nil
    end

    private def extract_type_name(type_decl)
      # Find the type_annotation node - it contains the type as a Match
      type_annotation_node = type_decl.find_child(:type_annotation)
      return nil unless type_annotation_node

      # The type_annotation has a Match child with the type name
      type_match = type_annotation_node.children.find { |c| c.is_a?(Grammy::Match) }
      type_match&.text
    end

  end
end
