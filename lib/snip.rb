module Snip

  class Answer
    attr_accessor :script
    attr_accessor :scores

    def initialize(script = "")
      @script = script
      @scores = {}
    end
  end


  class Evaluator
    def evaluate(answer)
      answer.scores[:generic] = nil
    end
  end


  class AccuracyEvaluator < Evaluator
    attr_reader :data

    def initialize(data)
      @data = data
    end

    def evaluate(answer)
      results = @data.collect do |row|
        executed = Snip::Interpreter.new(script:(answer.script),bindings:row).run
        executed.emit!
      end
      answer.scores[:accuracy] = 5.5
    end

#   Evaluate the solution for each case and each control. 
#   Find the median of the case values and the median of the control values.  
#   The mean of these two values will be the threshold, but we test four possible 
#   relations to the threshold to see which will produce the best balanced accuracy.  
#   The four relations are <, <=, >=, >. 
#   Balanced accuracy is ((tp / (tp + fn)) + (tn / (tn + fp))) / 2, where
#     tp = true positive
#     tn = true negative
#     fp = false positive
#     fn = false negative

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

    def emit!
      return @stack.pop
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