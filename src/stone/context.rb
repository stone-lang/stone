module Stone
  class Context

    delegate :[], :[]=, to: :@hash

    def initialize(parent_context)
      @hash = Hash.new{ |_h, k| parent_context[k] }
    end

  end
end
