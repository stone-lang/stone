module Stone
  class Error < StandardError

    attr_reader :location

    def initialize(message, location: nil)
      super(message)
      @location = location
    end

  end
end
