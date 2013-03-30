require 'spec_helper'

describe "BalancedAccuracyEvaluator" do
  describe "initialization" do
    it "should accept a dataset as an argument" do
      one_datum = [{"x1" => 2, group:1}]
      Search::BalancedAccuracyEvaluator.new(one_datum).data.should == one_datum
    end

    it "should split the dataset into positive and negative example subsets" do
      simple_data = [{x1:2, group:0}, {x1:1, group:1}]
      simpleEvaluator = Search::BalancedAccuracyEvaluator.new(simple_data)
      simpleEvaluator.positive_examples.length.should == 1
      simpleEvaluator.negative_examples.length.should == 1
      simpleEvaluator.data.length.should == 2
    end

    it "should raise an exception if any of the records don't have a :group assigned" do
      bad_data = [{x1:2, group:0}, {x1:1, group:nil}]
      lambda{ Search::BalancedAccuracyEvaluator.new(bad_data) }.should raise_error
    end

    it "should raise an exception if any of the records don't have a :group key" do
      bad_data = [{x1:2, group:0}, {x1:1, :class => 1}]
      lambda{ Search::BalancedAccuracyEvaluator.new(bad_data) }.should raise_error
      other_bad_data = [{x1:2, group:0}, {x1:1, "group" => 1}]
      lambda{ Search::BalancedAccuracyEvaluator.new(other_bad_data) }.should raise_error
    end

    it "should raise an exception if any of the records' :group is not in [0,1]" do
      bad_data = [{x1:2, group:0}, {x1:1, group:2}]
      lambda{ Search::BalancedAccuracyEvaluator.new(bad_data) }.should raise_error
    end
  end


  describe "BalancedAccuracyEvaluator.from_data_file" do
    it "should take a file path" do
      lambda{ Search::BalancedAccuracyEvaluator.from_data_file }.should raise_error(ArgumentError)
    end

    it "should raise an exception if no column is named 'group'" do
      path = './spec/fixtures/no_group_column.csv'
      lambda{ Search::BalancedAccuracyEvaluator.from_data_file(path) }.should raise_error(ArgumentError)
    end

    it "should raise an exception if any group measurement is missing"

    it "should raise an exception if any group measurement is not reported as 0 or 1"
    
    it "should read the header row to build the variable names list" do
      path = './spec/fixtures/five_columns.csv'
      evaluator = Search::BalancedAccuracyEvaluator.from_data_file(path)
      evaluator.data[-1].keys.should == ["X1", "X2", "X3", "X4", "X5", :group]
    end

    it "should create a data hash for every row of the file" do
      path = './spec/fixtures/five_columns.csv'
      evaluator = Search::BalancedAccuracyEvaluator.from_data_file(path)
      evaluator.data.length.should == 4
    end
  end


  describe "evaluate" do
    before(:each) do
      @trivial_answer = Snip::Answer.new("x1")
      @simple_data = [{"x1" => 0, group:0}, {"x1" => 1, group:1}, {"x1" => 2, group:1}]
    end

    it "should write two scores to the answer's scores hash" do
      Search::BalancedAccuracyEvaluator.new(@simple_data).evaluate(@trivial_answer)
      @trivial_answer.scores[:forward_balanced_accuracy].should_not be_nil
      @trivial_answer.scores[:backward_balanced_accuracy].should_not be_nil
    end

    it "should run the script once for every row of data" do
      scorer = Search::BalancedAccuracyEvaluator.new(@simple_data)
      runner = Snip::Interpreter.new(script:@trivial_answer.script)
      Snip::Interpreter.should_receive(:new).exactly(3).times.and_return(runner)
      scorer.evaluate(@trivial_answer)
    end

    it "should collect the top item of the stack every time the script is run" do
      scorer = Search::BalancedAccuracyEvaluator.new(@simple_data)
      runner = Snip::Interpreter.new(script:@trivial_answer.script)
      Snip::Interpreter.stub!(:new).and_return(runner)
      runner.should_receive(:emit!).exactly(3).times
      scorer.evaluate(@trivial_answer)
    end

    it "should calculate the median value for each class" do
      scorer = Search::BalancedAccuracyEvaluator.new(@simple_data)
      Search::Evaluator.should_receive(:median).exactly(2).times.and_return(77)
      scorer.evaluate(@trivial_answer)
    end

    it "should save a :balanced_accuracy_threshold score in the answer" do
      scorer = Search::BalancedAccuracyEvaluator.new(@simple_data)
      scorer.evaluate(@trivial_answer)
      @trivial_answer.scores[:balanced_accuracy_cutoff].should == 0.75
    end

    it "should return the balanced accuracy as ((tp / (tp + fn)) + (tn / (tn + fp))) / 2" do
      scorer = Search::BalancedAccuracyEvaluator.new(@simple_data)
      scorer.evaluate(@trivial_answer)
      @trivial_answer.scores[:forward_balanced_accuracy].should == 1.0
      @trivial_answer.scores[:backward_balanced_accuracy].should == 0.0


      backwards = [{"x1" => 1, group:0}, {"x1" => 0, group:1}, {"x1" => 0, group:1}]
      Search::BalancedAccuracyEvaluator.new(backwards).evaluate(@trivial_answer)
      @trivial_answer.scores[:forward_balanced_accuracy].should == 0.0
      @trivial_answer.scores[:backward_balanced_accuracy].should == 1.0
    end
  end


  describe "Evaluator.median(values)" do
    it "should raise an exception if there are any nil values in the list" do
      lambda{ Search::Evaluator.median([2,3,5,6,88,nil]) }.should raise_error
    end

    it "should raise an exception if the list is empty" do
      lambda{ Search::Evaluator.median([]) }.should raise_error
    end

    it "should return the middle value (after sorting) of an odd-length list" do
      Search::Evaluator.median([2,3,5,6,88]).should == 5.0
      Search::Evaluator.median([1,1,1]).should == 1.0
    end

    it "should return the average of the two middle numbers of an even-length list" do
      Search::Evaluator.median([-11,22,44,555]).should == 33.0
      Search::Evaluator.median([17,33]).should == 25.0
      Search::Evaluator.median([17,17]).should == 17.0
    end

    it "should return the only value for a 1-element list" do
      Search::Evaluator.median([13]).should == 13.0
    end
  end
end