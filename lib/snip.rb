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

    def self.median(numbers)
      sorted = numbers.compact.sort
      count = sorted.length
      result = case 
      when sorted.empty?
        nil
      when count.even?
        (sorted[count/2 - 1].to_f + sorted[count/2]) / 2.0
      else
        sorted[count/2].to_f
      end
      return result
    end
  end


  class BalancedAccuracyEvaluator < Evaluator
    attr_reader :data
    attr_reader :positive_examples
    attr_reader :negative_examples

    def initialize(data)
      data.each do |r|
        raise ArgumentError.new("A record has no :group assigned") if r[:group].nil?
        raise ArgumentError.new("A record as a :group assigned that is not 0 or 1") unless 
          [0,1].include? r[:group]
      end
      @data = data
      @positive_examples, @negative_examples = @data.partition {|r| r[:group] == 1}
    end

    def evaluate(answer)
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