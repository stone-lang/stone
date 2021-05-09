require "stone/builtin/function"
require "stone/builtin/value"


module Stone

  module Builtin

    class Any < Value

      def self.new!(object)
        object
      end

      def self.type
        "Any"
      end

      def type
        "Any"
      end

    end

  end

end
