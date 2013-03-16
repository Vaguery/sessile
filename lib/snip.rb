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


  class AccuracyEvaluator < Evaluator
    attr_reader :data

    def initialize(data)
      @data = data
    end

    def evaluate(answer)
      results = []
      @data.each_with_index do |row,idx|
        executed = Snip::Interpreter.new(script:(answer.script),bindings:row).run
        positive = (row[:group] == 1) || false
        result = executed.emit!
        results.push({index:idx, positive:positive, emitted:result})
      end

      positives, negatives = results.partition {|r| r[:positive]}
      median_0 = Evaluator.median(negatives.collect {|r| r[:emitted]})
      median_1 = Evaluator.median(positives.collect {|r| r[:emitted]})
      
      if median_0.nil? || median_1.nil?
        answer.scores[:accuracy] = nil
      else
        threshold = (median_0 + median_1)/2.0
        true_pos, true_neg, false_pos, false_neg = 0,0,0,0
        results.each do |r| 
          r[:predicted] = r[:emitted] < threshold ? 0 : 1
          case 
          when r[:predicted] && r[:positive]
            true_pos += 1
          when r[:predicted] && !r[:positive]
            false_pos += 1
          when !r[:predicted] && r[:positive]
            false_neg += 1
          else
            true_neg += 1
          end
        end
        answer.scores[:accuracy] = 
          ((true_pos / (true_pos + false_neg)) + (true_neg / (true_neg + false_pos))) / 2
      end

      puts answer.scores.inspect
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