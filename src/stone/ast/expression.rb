module Stone

  module AST

    class Expression < Node

      abstract :value

    end

  end

end


require "stone/ast/literal"
require "stone/ast/variable_reference"
require "stone/ast/operation"
require "stone/ast/block"
require "stone/ast/function_call"
require "stone/ast/method_call"
require "stone/ast/property_access"
require "stone/ast/function"
