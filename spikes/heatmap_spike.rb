require_relative '../lib/snip'

evaluator = Snip::BalancedAccuracyEvaluator.from_data_file('../data/MDR_sample_data.csv')

@tokens = [0, 1, 2, 4, 8, 16, -1, -2, -4, -8, -16, "+", "*", "-", "/", "<", "==", ">"] * 5 + evaluator.data[-1].keys
@tokens.delete(:group)

def random_script(length)
  length.times.inject("") {|script,token| "#{@tokens.sample} #{script}"}
end

File.open("./heatmap_spike.out", "w") do |output_file|
  output_file.puts "#{(0..400).inject('') {|line,i| line + 'R' + (i+1).to_s + ',' }}"
  300.times do |step|
    tokens = rand(50) + 10
    answer = Snip::Answer.new(random_script(tokens))
    emissions = evaluator.run_examples(answer,evaluator.data)
    line = emissions.inspect[2..-2]
    output_file.puts line
  end
end