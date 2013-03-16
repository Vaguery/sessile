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
      @simple_data = [{"x1" => 2, "sick?" => 2}, {"x1" => 33, "sick?" => 33}, {"x1" => 444, "sick?" => 444}]
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
end