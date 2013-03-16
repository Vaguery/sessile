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
      raise ArgumentError.new("no nil values in median calculation") if numbers.include?(nil)
      raise ArgumentError.new("median cannot be calculated for an empty list") if numbers.compact.empty?
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


  class EvaluatorError < StandardError
    def initialize(msg = "data file missing 'group' column")
      super(msg)
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

    def self.from_data_file(path)
      require 'csv'
      rows = []
      CSV.foreach(path, headers:true, converters: :numeric) do |file_row|
        row = file_row.to_hash
        row[:group] = row["group"]
        row.delete("group")
        rows << row
      end
      return BalancedAccuracyEvaluator.new(rows)
    end
    
    
    def run_examples(answer,rows)
      rows.collect do |row|
        Snip::Interpreter.new(script:answer.script, bindings:row).run.emit!
      end
    end
    
    
    def apply_threshold_to_predictions(numbers,threshold)
      numbers.collect {|num| num <= threshold ? 0 : 1 }
    end
    
    
    def balanced_accuracy(predicted_positives, predicted_negatives)
      false_positives = predicted_negatives.count(1).to_f
      false_negatives = predicted_positives.count(0).to_f
      true_positives = predicted_positives.count(1).to_f
      true_negatives = predicted_negatives.count(0).to_f
      
      sensitivity = true_positives / (true_positives + false_negatives)
      specificity = true_negatives / (true_negatives + false_positives)
      
      return (sensitivity + specificity) / 2
    end


    def evaluate(answer)
      pos_values = run_examples(answer,@positive_examples)
      neg_values = run_examples(answer,@negative_examples)

      all_values = pos_values + neg_values
      if all_values.include?(nil) || pos_values.empty? || neg_values.empty?
        answer.scores[:balanced_accuracy_cutoff] = nil
        answer.scores[:forward_balanced_accuracy] = nil
        answer.scores[:backward_balanced_accuracy] = nil
      else
        pos_median = Snip::Evaluator.median(pos_values)
        neg_median = Snip::Evaluator.median(neg_values)
        threshold = (neg_median + pos_median) / 2

        predicted_positives = apply_threshold_to_predictions(pos_values, threshold)
        predicted_negatives = apply_threshold_to_predictions(neg_values, threshold)

        answer.scores[:balanced_accuracy_cutoff] = threshold

        forward_threshold_score = balanced_accuracy(predicted_positives, predicted_negatives)
        backward_threshold_score = 1.0 - forward_threshold_score

        answer.scores[:forward_balanced_accuracy] = forward_threshold_score
        answer.scores[:backward_balanced_accuracy] = backward_threshold_score
      end
      return answer
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