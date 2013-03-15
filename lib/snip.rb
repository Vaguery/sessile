module Snip

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


  class Interpreter
    attr_accessor :stack
    attr_accessor :script
    attr_accessor :steps
    attr_accessor :bindings

    def initialize(options = {})
      @stack = options[:stack] || [] 
      @script = options[:script] || ""
      @bindings = options[:bindings] || {}
      @steps = 0
    end

    
    def run
      bound_variables = @bindings.keys
      tokens = @script.split
      tokens.each do |token|
        @steps += 1
         
        if bound_variables.include?(token)
          @stack.push @bindings[token]
        else
          case token
          when /[-+]?([0-9]*\.[0-9]+|[0-9]+)/
            @stack.push token.to_f
          when /[\+\-\*\/]/
            handle_arithmetic(token)
          when "==", "<", ">", ">=", "<="
            handle_comparison(token)
          end
        end
      end
      return self
    end


    def handle_arithmetic(token)
      if @stack.length > 1
        a,b = @stack.pop(2)
        result = case token
        when "+"
          a + b
        when "-"
          a - b
        when "*"
          a * b
        when "/"
          b == 0.0 ? 0.0 : a / b
        end
        @stack.push result
      end
    end


    def handle_comparison(token)
      if @stack.length > 1
        a,b = @stack.pop(2)
        result = case token
        when "=="
          a == b ? 1.0 : 0.0
        when "<"
          a < b ? 1.0 : 0.0
        when "<="
          a <= b ? 1.0 : 0.0
        when ">"
          a > b ? 1.0 : 0.0
        when ">="
          a >= b ? 1.0 : 0.0
        end
        @stack.push result
      end

    end
    
  end

end