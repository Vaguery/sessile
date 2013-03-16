require 'spec_helper'

describe "accuracy evaluation" do
  describe "initialization" do
    it "should accept a dataset as an argument" do
      simple_data = [{"x1" => 2}]
      Snip::AccuracyEvaluator.new(simple_data).data.should == simple_data
    end
  end

  describe "evaluate" do
    before(:each) do
      @trivial_answer = Snip::Answer.new("x1")
      @simple_data = [{"x1" => 0, "class" => 0}, {"x1" => 1, "class" => 1}, {"x1" => 2, "class" => 1}]
    end

    it "should write a score to the answer's scores hash" do
      Snip::AccuracyEvaluator.new([]).evaluate(@trivial_answer)
      @trivial_answer.scores.keys.should == [:accuracy]
    end

    it "should run the script once for every row of data" do
      thud = Snip::Interpreter.new(script:"x1",bindings:{})
      Snip::Interpreter.should_receive(:new).exactly(3).times.and_return(thud)
      Snip::AccuracyEvaluator.new(@simple_data).evaluate(@trivial_answer)
    end

    it "should collect the top item of the stack every time the script is run" do
      thud = Snip::Interpreter.new(script:"x1",bindings:{})
      Snip::Interpreter.stub(:new).and_return(thud)
      thud.should_receive(:emit!).exactly(3).times
      Snip::AccuracyEvaluator.new(@simple_data).evaluate(@trivial_answer)
    end

    it "should calculate the median value for each class" 

    it "should set the threshold to the mean of those two medians"

    it "should make generate a prediction for each row based on the mean-of-medians threshold"

    it "should return the balanced accuracy as ((tp / (tp + fn)) + (tn / (tn + fp))) / 2"
  end


  describe "Evaluator.median(values)" do
    it "should return the middle value (after sorting) of an odd-length list" do
      Snip::Evaluator.median([2,3,5,6,88]).should == 5.0
      Snip::Evaluator.median([1,1,1]).should == 1.0
    end

    it "should return the average of the two middle numbers of an even-length list" do
      Snip::Evaluator.median([-11,22,44,555]).should == 33.0
      Snip::Evaluator.median([17,33]).should == 25.0
      Snip::Evaluator.median([17,17]).should == 17.0
    end

    it "should return the only value for a 1-element list" do
      Snip::Evaluator.median([13]).should == 13.0
    end
    
    it "should return nil for an empty list" do
      Snip::Evaluator.median([]).should == nil
    end
  end
end