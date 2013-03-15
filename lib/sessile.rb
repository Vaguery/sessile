module Sessile

  class Answer
    attr_accessor :script
    attr_reader :context
    attr_accessor :stack

    def initialize(script = "",context=Array.new)
      @script = script
      @context = context
      @stack = Array.new
    end
    
    
  end

end