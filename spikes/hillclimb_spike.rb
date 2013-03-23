require_relative '../lib/snip'

evaluator = Snip::BalancedAccuracyEvaluator.from_data_file('../data/MDR_sample_data.csv')

@tokens = [0, 1, 2, 4, 8, 16, -1, -2, -4, -8, -16, "+", "*", "-", "/", "<", "==", ">"] * 5 + 
  evaluator.data[-1].keys
@tokens.delete(:group)

def random_script(length)
  length.times.inject("") {|script,token| "#{@tokens.sample} #{script}"}
end


def mutant_from_script(script,probability_per_token=0.1)
  wt_tokens = script.split
  mutant_tokens = wt_tokens.collect {|t| Random.rand()<=probability_per_token ? @tokens.sample : t}
  return Snip::Answer.new(mutant_tokens.join(" "))
end

File.open("./hillclimb_spike.out", "w") do |output_file|
  mutation_rate = 0.5
  output_file.puts "t,mutation_rate,current_score,current_script,current_wtf,mutant_score,mutant_script,mutant_wtf"
  answer = Snip::Answer.new(random_script(40))
  evaluator.evaluate(answer)
  answer_score = [answer.scores[:forward_balanced_accuracy],answer.scores[:backward_balanced_accuracy]].max
  answer_wtf = Snip::Interpreter.new(script:answer.script).wtf.inspect
  output_file.puts "0,#{mutation_rate},#{answer_score},#{answer.script.inspect},#{answer_wtf},,"

  climb_length = 500
  300.times do |start|
    p "mutation rate: #{mutation_rate.round(6)}, best score: #{answer_score}, best model: #{answer_wtf}"
    climb_length.times do |step|
      mutant = mutant_from_script(answer.script,mutation_rate)
      evaluator.evaluate(mutant)
      
      answer_score = [answer.scores[:forward_balanced_accuracy],answer.scores[:backward_balanced_accuracy]].max
      answer_wtf = Snip::Interpreter.new(script:answer.script).wtf.inspect
      mutant_score = [mutant.scores[:forward_balanced_accuracy],mutant.scores[:backward_balanced_accuracy]].max
      mutant_wtf = Snip::Interpreter.new(script:mutant.script).wtf.inspect

      answer = mutant if answer_score <= mutant_score
      output_file.puts "#{climb_length*start + step},#{mutation_rate},#{answer_score},#{answer.script.inspect},#{answer_wtf},#{mutant_score},#{mutant.script.inspect},#{mutant_wtf}"
    end
    mutation_rate = (mutation_rate < 0.01 ? 0.8 : (mutation_rate * 0.5))
  end
end