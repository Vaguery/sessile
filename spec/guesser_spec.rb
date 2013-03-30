require 'spec_helper'

describe "Guesser" do
  describe "initialization" do
    it "should accept a list of operator tokens" do
      Search::Guesser.new(operators:["foo"]).operators.should == ["foo"]
    end

    it "should accept a list of variable tokens" do
      Search::Guesser.new(variables:["bar"]).variables.should == ["bar"]
    end

    it "should accept integer limits, which default to nil" do
      guesses_ints = Search::Guesser.new(integer_limits:[12,33])
      guesses_ints.integer_limits[:max].should == 33
      guesses_ints.integer_limits[:min].should == 12
      Search::Guesser.new.integer_limits.should == nil
    end

    it "should accept float limits, which default to nil" do
      guesses_ints = Search::Guesser.new(float_limits:[341.2,0.0])
      guesses_ints.float_limits[:max].should == 341.2
      guesses_ints.float_limits[:min].should == 0.0
      Search::Guesser.new.float_limits.should == nil
    end
  end


  describe "guess" do
    it "should accept a number of tokens as an argument" do
      fubar = Search::Guesser.new(operators:["a","b","c"])
      fubar.guess(20).length.should == 39
    end

    it "should raise an exception if no tokens or constants are defined" do
      not_much = Search::Guesser.new
      lambda{ not_much.guess(12) }.should raise_error(ArgumentError)
    end

    it "should use the known operators and variables as tokens" do
      fubar = Search::Guesser.new(operators:["a","b","c"], variables:["X1"])
      used_tokens = fubar.guess(100).split.uniq.sort
      used_tokens.should == ["X1", "a", "b", "c"]
    end

    it "should insert integers if the :use_integers flag is true" do
      numbery = Search::Guesser.new(operators:["+"],integer_limits:[1,4])
      num_script = numbery.guess(100,use_integers:true)
      num_script.split.uniq.sort.should == ["+", "1", "2", "3", "4"]
    end

    it "should not insert integers if the :use_integers flag is missing" do
      numberlos = Search::Guesser.new(operators:["+"],integer_limits:[1,11])
      num_script = numberlos.guess(100)
      num_script.split.uniq.sort.should == ["+"]
    end

    it "should insert just that integer if both limits are the same" do
      monotone = Search::Guesser.new(operators:["+"],integer_limits:[11,11])
      num_script = monotone.guess(100,use_integers:true)
      num_script.split.uniq.sort.should == ["+", "11"]
    end

    it "should raise and exception if the flag is set but the limits are missing" do
      forgetful = Search::Guesser.new(operators:["+"])
      lambda{ forgetful.guess(100,use_integers:true)}.should raise_error(ArgumentError)
    end

    it "should insert floats if the :use_floats flag is true" do
      numbery = Search::Guesser.new(float_limits:[1.0,-4.0])
      num_script = numbery.guess(100,use_floats:true)
      converted_tokens = num_script.split.uniq.sort.collect {|t| t.to_f}
      converted_tokens.each {|f| (-4.0..1.0).should include f}
    end

    it "should not insert floats if the :use_floats flag is missing" do
      numberlos = Search::Guesser.new(operators:["+"],float_limits:[0.0,1.0])
      num_script = numberlos.guess(100)
      num_script.split.uniq.sort.should == ["+"]
    end

    it "should insert just that float if both limits are the same" do
      monotone = Search::Guesser.new(operators:["+"],float_limits:[1.0,1.0])
      num_script = monotone.guess(100,use_floats:true)
      num_script.split.uniq.sort.should == ["+", "1.0"]
    end

    it "should raise and exception if the flag is set but the limits are missing" do
      forgetful = Search::Guesser.new(operators:["+"])
      lambda{ forgetful.guess(100,use_floats:true)}.should raise_error(ArgumentError)
    end
  end
end