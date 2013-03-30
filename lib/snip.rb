module Snip

  class Answer
    attr_accessor :script
    attr_accessor :scores

    def initialize(script = "")
      @script = script
      @scores = {}
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
          @stack.push @bindings[token].to_f
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


    def wtf
      @stack = []
      bound_variables = @bindings.keys
      tokens = @script.split
      tokens.each do |token|
        @steps += 1
         
        if bound_variables.include?(token)
          @stack.push token
        else
          case token
          when /[-+]?([0-9]*\.[0-9]+|[0-9]+)/
            @stack.push token.to_s
          when "+","*","-","/","==", "<", ">", ">=", "<="
            wtf_arity_2(token)
          else
            @stack.push token
          end
        end
      end
      self.emit! 
    end


    def wtf_arity_2(operator)
      if @stack.length > 1
        a,b = stack.pop(2)
        @stack.push  "(#{a} #{operator} #{b})"
      end
    end


    def emit!
      return @stack.pop
    end


    def handle_arithmetic(token)
      if @stack.length > 1
        a,b = @stack.pop(2)
        result = case token
        when "+"
          a.to_f + b
        when "-"
          a.to_f - b
        when "*"
          a.to_f * b
        when "/"
          b == 0.0 ? 0.0 : a.to_f / b
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