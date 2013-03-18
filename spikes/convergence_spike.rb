require_relative '../lib/snip'

def subsample_evaluator(full_one,count)
  positives,negatives = full_one.data.partition {|d| d[:group]==1.0}
  Snip::BalancedAccuracyEvaluator.new(positives.sample(count) + negatives.sample(count))
end

full_evaluator = Snip::BalancedAccuracyEvaluator.from_data_file('../data/MDR_sample_data.csv')

sample_sizes = [1,2,4,8,16,32,64,128]

sample_evaluators = 
50.times.collect do
  sample_sizes.collect do |size|
    Snip::BalancedAccuracyEvaluator.new(full_evaluator.data.sample(size))
  end
end.flatten




@tokens = [0, 1, 2, 4, 8, 16, -1, -2, -4, -8, -16, "+", "*", "-", "/", "<", "==", ">"] * 5 + full_evaluator.data[-1].keys
@tokens.delete(:group)


def random_script(length)
  length.times.inject("") {|script,token| "#{@tokens.sample} #{script}"}
end

File.open("./convergence_spike.out", "w") do |output_file|
  output_file.puts "script,sample,score"
  
  1000.times do |iteration|
    tokens = rand(50) + 10
    answer = Snip::Answer.new(random_script(tokens))
    full_evaluator.evaluate(answer)
    output_file.puts "#{iteration},200,#{answer.scores[:forward_balanced_accuracy] || 'NA'}"

    sample_evaluators.each do |evaluator|
      evaluator.evaluate(answer)
      # p "#{iteration},#{evaluator.data.length},#{answer.scores[:forward_balanced_accuracy]  || 'NA'}"
      output_file.puts "#{iteration},#{evaluator.data.length},#{answer.scores[:forward_balanced_accuracy]  || 'NA'}"
    end
  end
end