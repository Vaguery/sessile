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
      bad_data = [{x1:2, group:0}, {x1:1, group:2}]
      lambda{ Snip::BalancedAccuracyEvaluator.new(bad_data) }.should raise_error
    end
  end


  describe "BalancedAccuracyEvaluator.from_data_file" do
    it "should take a file path"
    it "should open the file"
    it "should raise an exception if no column is named 'group'"
    it "should raise an exception if any group measurement is missing"
    it "should raise an exception if any group measurement is not reported as 0 or 1"
    it "should read the header row to build the variable names list"
    it "should create a data hash for every row of the file"
    it "should return a BalancedAccuracyEvaluator initialized with the data"
  end


  describe "evaluate" do
    before(:each) do
      @trivial_answer = Snip::Answer.new("x1")
      @simple_data = [{"x1" => 0, group:0}, {"x1" => 1, group:1}, {"x1" => 2, group:1}]
    end

    it "should write a score to the answer's scores hash" do
      Snip::BalancedAccuracyEvaluator.new(@simple_data).evaluate(@trivial_answer)
      @trivial_answer.scores[:balanced_accuracy].should_not be_nil
    end

    it "should run the script once for every row of data" do
      scorer = Snip::BalancedAccuracyEvaluator.new(@simple_data)
      runner = Snip::Interpreter.new(script:@trivial_answer.script)
      Snip::Interpreter.should_receive(:new).exactly(3).times.and_return(runner)
      scorer.evaluate(@trivial_answer)
    end

    it "should collect the top item of the stack every time the script is run" do
      scorer = Snip::BalancedAccuracyEvaluator.new(@simple_data)
      runner = Snip::Interpreter.new(script:@trivial_answer.script)
      Snip::Interpreter.stub!(:new).and_return(runner)
      runner.should_receive(:emit!).exactly(3).times
      scorer.evaluate(@trivial_answer)
    end

    it "should calculate the median value for each class" do
      scorer = Snip::BalancedAccuracyEvaluator.new(@simple_data)
      Snip::Evaluator.should_receive(:median).exactly(2).times.and_return(77)
      scorer.evaluate(@trivial_answer)
    end

    it "should save a :balanced_accuracy_threshold score in the answer" do
      scorer = Snip::BalancedAccuracyEvaluator.new(@simple_data)
      scorer.evaluate(@trivial_answer)
      @trivial_answer.scores[:balanced_accuracy_cutoff].should == 0.75
    end

    it "should return the balanced accuracy as ((tp / (tp + fn)) + (tn / (tn + fp))) / 2" do
      scorer = Snip::BalancedAccuracyEvaluator.new(@simple_data)
      scorer.evaluate(@trivial_answer)
      @trivial_answer.scores[:balanced_accuracy].should == 1.0

      backwards = [{"x1" => 1, group:0}, {"x1" => 0, group:1}, {"x1" => 0, group:1}]
      Snip::BalancedAccuracyEvaluator.new(backwards).evaluate(@trivial_answer)
      @trivial_answer.scores[:balanced_accuracy].should == 0.0
    end
  end


  describe "Evaluator.median(values)" do
    it "should raise an exception if there are any nil values in the list" do
      lambda{ Snip::Evaluator.median([2,3,5,6,88,nil]) }.should raise_error
    end

    it "should raise an exception if the list is empty" do
      lambda{ Snip::Evaluator.median([]) }.should raise_error
    end

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
  end
end