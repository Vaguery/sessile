require 'spec_helper'

describe "SessileLanguage" do
  describe "Answer" do
    before(:each) do
      @three_token_script = "x_12 x_3 x_22"
      @one_row_data = [{x_12:2, x_3:1, x_22:0}]
    end

    it "should take a script as an initialization argument, with default to empty string" do
      Sessile::Answer.new.script.should == ""
      Sessile::Answer.new(@three_token_script).script.should == @three_token_script
    end

    it "should take an Array of assignments as a second initialization arg" do
      Sessile::Answer.new("foo").context.should be_empty
      Sessile::Answer.new("foo",@one_row_data).context[0][:x_3].should be 1
    end

    it "should have a stack" do
      Sessile::Answer.new.stack.should be_empty
    end
  end
end