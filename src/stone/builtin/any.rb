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


require "stone/builtin/function"
require "stone/builtin/boolean"
require "stone/builtin/number"
require "stone/builtin/text"
require "stone/builtin/pair"
require "stone/builtin/list"
require "stone/builtin/map"
require "stone/builtin/error"
