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
end