require 'spec_helper'

describe "BalancedAccuracyEvaluator" do
  describe "initialization" do
    it "should accept a dataset as an argument" do
      one_datum = [{"x1" => 2, group:1}]
      Snip::BalancedAccuracyEvaluator.new(one_datum).data.should == one_datum
    end

    it "should split the dataset into positive and negative example subsets" do
      simple_data = [{x1:2, group:0}, {x1:1, group:1}]
      simpleEvaluator = Snip::BalancedAccuracyEvaluator.new(simple_data)
      simpleEvaluator.positive_examples.length.should == 1
      simpleEvaluator.negative_examples.length.should == 1
      simpleEvaluator.data.length.should == 2
    end

    it "should raise an exception if any of the records don't have a :group assigned" do
      bad_data = [{x1:2, group:0}, {x1:1, group:nil}]
      lambda{ Snip::BalancedAccuracyEvaluator.new(bad_data) }.should raise_error
    end

    it "should raise an exception if any of the records don't have a :group key" do
      bad_data = [{x1:2, group:0}, {x1:1, :class => 1}]
      lambda{ Snip::BalancedAccuracyEvaluator.new(bad_data) }.should raise_error
      other_bad_data = [{x1:2, group:0}, {x1:1, "group" => 1}]
      lambda{ Snip::BalancedAccuracyEvaluator.new(other_bad_data) }.should raise_error
    end

    it "should raise an exception if any of the records' :group is not in [0,1]" do
      
    end
  end

  describe "evaluate" do
    before(:each) do
      @trivial_answer = Snip::Answer.new("x1")
      @simple_data = [{"x1" => 0, group:0}, {"x1" => 1, group:1}, {"x1" => 2, group:1}]
    end

    it "should write a score to the answer's scores hash" 

    it "should run the script once for every row of data"

    it "should collect the top item of the stack every time the script is run"

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