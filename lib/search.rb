module Search

  class Guesser
    attr_reader :operators, :variables
    attr_reader :integer_limits, :float_limits

    def initialize(args = {})
      @operators = args[:operators] || []
      @variables = args[:variables] || []
      @integer_limits = parse_range_limits(args[:integer_limits])
      @float_limits = parse_range_limits(args[:float_limits])
    end
    

    def parse_range_limits(argument_array)
      return nil if argument_array.nil?
      {min:argument_array.min, max:argument_array.max}
    end


    def guess(length,args={})
      available_tokens = @operators + @variables
      available_tokens << "integer_placeholder" if args[:use_integers]
      available_tokens << "float_placeholder" if args[:use_floats]
      raise(ArgumentError.new("No tokens are defined!")) if available_tokens.empty?

      tokens = length.times.collect {available_tokens.sample}
      tokens = tokens.collect {|t| t=="integer_placeholder" ? random_integer : t}
      tokens = tokens.collect {|t| t=="float_placeholder" ? random_float : t}
      return tokens.join(" ")
    end


    def random_integer
      raise(ArgumentError.new("Integer limits are not set")) if integer_limits.nil?
      return integer_limits[:max] if (integer_limits[:max] == integer_limits[:min])
      return rand((integer_limits[:max] - integer_limits[:min]) + integer_limits[:min]) + 1
    end
    
    def random_float
      raise(ArgumentError.new("Float limits are not set")) if float_limits.nil?
      return float_limits[:max] if (float_limits[:max] == float_limits[:min])
      return rand() * (float_limits[:max] - float_limits[:min]) + float_limits[:min]
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
        pos_median = Search::Evaluator.median(pos_values)
        neg_median = Search::Evaluator.median(neg_values)
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
end