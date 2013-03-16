require_relative '../lib/snip'

evaluator = Snip::BalancedAccuracyEvaluator.from_data_file('../data/MDR_sample_data.csv')

@tokens = [0, 1, 2, 4, 8, 16, -1, -2, -4, -8, -16, "+", "*", "-", "/", "<", "==", ">"] * 5 + evaluator.data[-1].keys
@tokens.delete(:group)

def random_script(length)
  length.times.inject("") {|script,token| "#{@tokens.sample} #{script}"}
end


File.open("./random_spike.out", "w") do |output_file|
  output_file.puts "t,forward_score,backward_score,tokens,script"
  max = 0.0
  100.times do |step|
    new_max = false
    tokens = rand(30) + 10
    answer = Snip::Answer.new(random_script(tokens))
    evaluator.evaluate(answer)
    if answer.scores[:forward_balanced_accuracy] >= max || answer.scores[:backward_balanced_accuracy] >= max
      max = [answer.scores[:forward_balanced_accuracy],answer.scores[:backward_balanced_accuracy]].max
      new_max = true
    end
    line =  "#{step}, #{answer.scores[:forward_balanced_accuracy].round(6)}, #{answer.scores[:backward_balanced_accuracy].round(6)}, #{tokens}" 
    line +=  ", #{answer.script.strip.inspect}"
    output_file.puts line
    p line if new_max
  end
end