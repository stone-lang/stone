require "stone/builtin/value"


module Stone

  module Builtin

    class Object < Value

      def klass
      end

      def properties
        {}
      end

      def methods
        {}
      end

    end

  end

end


require "stone/builtin/list"
require "stone/builtin/pair"
require "stone/builtin/map"
