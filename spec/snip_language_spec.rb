require 'spec_helper'

describe "SnipLanguage" do
  describe "Answer" do
    it "should take a script as an initialization argument, with default to empty string" do
      Snip::Answer.new.script.should == ""
      Snip::Answer.new("x_12 x_3 x_22").script.should == "x_12 x_3 x_22"
    end
  end


  describe "Interpreter" do
    describe "initialization" do
      it "should have an empty stack" do
        Snip::Interpreter.new.stack.should == []
      end

      it "should accept a stack as an optional argument" do
        Snip::Interpreter.new(stack:[2.0]).stack.should == [2.0]
      end

      it "should accept a script as an optional argument" do
        Snip::Interpreter.new(script:"foo bar").script.should == "foo bar"
      end

      it "should accept a hash of variable bindings as an optional argument" do
        Snip::Interpreter.new(bindings:{"x"=> 3.0}).bindings.should == {"x" => 3.0}
        Snip::Interpreter.new.bindings.should == {}
      end
    end
  end


  describe "run" do
    it "should take one step for every space-delimited token in the script" do
      Snip::Interpreter.new(script:"foo bar").run.steps.should == 2
      Snip::Interpreter.new(script:"   foo\t\t bar \nbaz").run.steps.should == 3
    end

    it "should ignore unknown tokens" do
      gibberish = Snip::Interpreter.new(script:"foo bar")
      gibberish.stack.should_not_receive(:push)
      gibberish.run
    end


    describe "variables" do
      it "should push the values associated with tokens it recognizes as variable names" do
        knows_x = Snip::Interpreter.new(script:"x",bindings:{"x" => 33})
        knows_x.run.stack.should == [33]
      end

      it "should still work if only some variables are defined" do
        half_wit = Snip::Interpreter.new(script:"foo bar", bindings:{"foo" => 881})
        half_wit.stack.should_receive(:push).with(881)
        half_wit.run
      end
    end


    describe "literals" do
      it "should push numbers" do
        Snip::Interpreter.new(script:"3.3 -2").run.stack.should == [3.3, -2]
        Snip::Interpreter.new(script:"+2213.44445678").run.stack.should == [2213.44445678]
      end
    end


    describe "arithmetic" do
      describe "+" do
        it "should pop two arguments and replace them with their sum" do
          Snip::Interpreter.new(script:"1 2 3 +").run.stack.should == [1,5]
        end

        it "should return a float" do
          Snip::Interpreter.new(script:"1 2 3 +").run.stack[-1].should be_a_kind_of(Float)
        end

        it "should fail if there aren't enough items on the stack" do
          Snip::Interpreter.new(script:"1 +").run.stack.should == [1.0]
          Snip::Interpreter.new(script:"+ 2 3").run.stack.should == [2.0, 3.0]
        end
      end

      
      describe "-" do
        it "should pop two arguments and replace them with their difference" do
          Snip::Interpreter.new(script:"1 2 4 -").run.stack.should == [1,-2]
        end

        it "should fail if there aren't enough items on the stack" do
          Snip::Interpreter.new(script:"1 -").run.stack.should == [1.0]
          Snip::Interpreter.new(script:"- 2 3").run.stack.should == [2.0, 3.0]
        end
      end


      describe "*" do
        it "should pop two arguments and replace them with their product" do
          Snip::Interpreter.new(script:"1 -2 4 *").run.stack.should == [1,-8]
        end

        it "should fail if there aren't enough items on the stack" do
          Snip::Interpreter.new(script:"1 *").run.stack.should == [1.0]
          Snip::Interpreter.new(script:"* 2 3").run.stack.should == [2.0, 3.0]
        end
      end


      describe "/" do
        it "should pop two arguments and replace them with their quotient" do
          Snip::Interpreter.new(script:"1 2 4 /").run.stack.should == [1,0.5]
        end

        it "should fail if there aren't enough items on the stack" do
          Snip::Interpreter.new(script:"1 /").run.stack.should == [1.0]
          Snip::Interpreter.new(script:"/ 2 3").run.stack.should == [2.0, 3.0]
        end

        it "should return 0.0 if it attempts to divide by 0.0" do
          Snip::Interpreter.new(script:"1 2 0 /").run.stack.should == [1,0.0]
        end
      end
    end


    describe "comparisons" do
      describe "==" do
        it "should pop two arguments and replace them with a pseudoboolean indicating equality" do
          Snip::Interpreter.new(script:"1 2 3 ==").run.stack.should == [1,0.0]
          Snip::Interpreter.new(script:"1 2 2 ==").run.stack.should == [1,1.0]
        end

        it "should fail if there aren't enough items on the stack" do
          Snip::Interpreter.new(script:"1 ==").run.stack.should == [1.0]
          Snip::Interpreter.new(script:"== 2 3").run.stack.should == [2.0, 3.0]
        end
      end


      describe "<" do
        it "should pop two arguments and replace them with a pseudoboolean indicating a < b" do
          Snip::Interpreter.new(script:"1 2 3 <").run.stack.should == [1,1.0]
          Snip::Interpreter.new(script:"1 2 2 <").run.stack.should == [1,0.0]
          Snip::Interpreter.new(script:"1 3 2 <").run.stack.should == [1,0.0]
        end


        it "should fail if there aren't enough items on the stack" do
          Snip::Interpreter.new(script:"1 <").run.stack.should == [1.0]
          Snip::Interpreter.new(script:"< 2 3").run.stack.should == [2.0, 3.0]
        end
      end


      describe ">" do
        it "should pop two arguments and replace them with a pseudoboolean indicating a < b" do
          Snip::Interpreter.new(script:"1 2 3 >").run.stack.should == [1,0.0]
          Snip::Interpreter.new(script:"1 2 2 >").run.stack.should == [1,0.0]
          Snip::Interpreter.new(script:"1 3 2 >").run.stack.should == [1,1.0]
        end

        it "should fail if there aren't enough items on the stack" do
          Snip::Interpreter.new(script:"1 >").run.stack.should == [1.0]
          Snip::Interpreter.new(script:"> 2 3").run.stack.should == [2.0, 3.0]
        end
      end


      describe ">=" do
        it "should pop two arguments and replace them with a pseudoboolean indicating a < b" do
          Snip::Interpreter.new(script:"1 2 3 >=").run.stack.should == [1,0.0]
          Snip::Interpreter.new(script:"1 2 2 >=").run.stack.should == [1,1.0]
          Snip::Interpreter.new(script:"1 3 2 >=").run.stack.should == [1,1.0]
        end

        it "should fail if there aren't enough items on the stack" do
          Snip::Interpreter.new(script:"1 >=").run.stack.should == [1.0]
          Snip::Interpreter.new(script:">= 2 3").run.stack.should == [2.0, 3.0]
        end
      end


      describe "<=" do
        it "should pop two arguments and replace them with a pseudoboolean indicating a < b" do
          Snip::Interpreter.new(script:"1 2 3 <=").run.stack.should == [1,1.0]
          Snip::Interpreter.new(script:"1 2 2 <=").run.stack.should == [1,1.0]
          Snip::Interpreter.new(script:"1 3 2 <=").run.stack.should == [1,0.0]
        end

        it "should fail if there aren't enough items on the stack" do
          Snip::Interpreter.new(script:"1 <=").run.stack.should == [1.0]
          Snip::Interpreter.new(script:"<= 2 3").run.stack.should == [2.0, 3.0]
        end
      end
    end

  describe "wtf" do
    it "should generate a string result from the script input" do
      Snip::Interpreter.new(script:"1 2 3 ==").wtf.should be_a_kind_of(String)
    end

    it "should produce a parenthesized human-readable string for basic operations" do
      Snip::Interpreter.new(script:"1 2 +").wtf.should == "(1 + 2)"
      Snip::Interpreter.new(script:"1 2 - ").wtf.should == "(1 - 2)"
      Snip::Interpreter.new(script:"1 2 * ").wtf.should == "(1 * 2)"
      Snip::Interpreter.new(script:"1 2 / ").wtf.should == "(1 / 2)"
      Snip::Interpreter.new(script:"1 2 ==").wtf.should == "(1 == 2)"
      Snip::Interpreter.new(script:"1 2 < ").wtf.should == "(1 < 2)"
      Snip::Interpreter.new(script:"1 2 > ").wtf.should == "(1 > 2)"
      Snip::Interpreter.new(script:"1 2 <=").wtf.should == "(1 <= 2)"
      Snip::Interpreter.new(script:"1 2 >=").wtf.should == "(1 >= 2)"
    end

    it "should work assume any unrecognized token is a variable name" do
      Snip::Interpreter.new(script:"foo bar + 3.3 -").wtf.should == "((foo + bar) - 3.3)"
    end

    it "should only return the topmost item from the stack" do
      Snip::Interpreter.new(script:"1 2 + 3 4 * 5 6 1.1 -2.2 + + 9 *").wtf.should == "((6 + (1.1 + -2.2)) * 9)"
    end

  end

  end
end