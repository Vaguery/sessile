require_relative '../lib/snip'

evaluator = Snip::BalancedAccuracyEvaluator.from_data_file('../data/MDR_sample_data.csv')

@tokens = ["k", "+", "*", "-", "/", "<", "==", ">"] * 5 + 
  evaluator.data[-1].keys
@tokens.delete(:group)


def clean_float(range)
  ((Random.rand()-0.5) * range).round(3)
end

def random_script(length)
  words = length.times.collect {@tokens.sample}
  words = words.collect {|w| w=="k" ? (clean_float(100).to_s) : w}
  return words.join(" ")
end


def mutant_from_script(script,probability_per_token=0.1)
  wt_tokens = script.split
  mutant_tokens = wt_tokens.collect {|t| Random.rand()<=probability_per_token ? @tokens.sample : t}
  mutant_tokens = mutant_tokens.collect {|w| (w=="k") ? (clean_float(100).to_s) : w}
  return Snip::Answer.new(mutant_tokens.join(" "))
end


5.times do |run_number|
  File.open("./hillclimb_spike-#{run_number}.out", "w") do |output_file|
    climb_length = 250
    mutation_rate = 0.5
    change_records = []
    improvement_records = []
    silent_records = []
    moving_average_window = 100

    output_file.puts "t,mutation_rate,change_rate,silent_rate,improvement_rate,current_score,current_script,current_wtf,mutant_score,mutant_script,mutant_wtf"

    answer = Snip::Answer.new(random_script(40))
    evaluator.evaluate(answer)
    answer_score = [answer.scores[:forward_balanced_accuracy],answer.scores[:backward_balanced_accuracy]].max
    answer_wtf = Snip::Interpreter.new(script:answer.script).wtf.inspect
    
    output_file.puts "0,#{mutation_rate},1.0,1.0,1.0,#{answer_score},#{answer.script.inspect},#{answer_wtf},,"

    200.times do |start|
      p "mutation rate: #{mutation_rate.round(5)}, best score: #{answer_score.round(5)}, best model: #{answer_wtf.delete('"')}"
      climb_length.times do |step|
        mutant = mutant_from_script(answer.script,mutation_rate)
        evaluator.evaluate(mutant)
        
        answer_score = [answer.scores[:forward_balanced_accuracy],answer.scores[:backward_balanced_accuracy]].max
        answer_wtf = Snip::Interpreter.new(script:answer.script).wtf.inspect
        mutant_score = [mutant.scores[:forward_balanced_accuracy],mutant.scores[:backward_balanced_accuracy]].max
        mutant_wtf = Snip::Interpreter.new(script:mutant.script).wtf.inspect

        if answer_score <= mutant_score
          change_records << (answer_wtf != mutant_wtf)
          silent_records << ((answer_wtf == mutant_wtf) && (answer.script != mutant.script))
          improvement_records << (answer_score < mutant_score)
          answer = mutant
        else
          change_records << false
          silent_records << false
          improvement_records << false
        end

        change_records = change_records[-moving_average_window..-1] if change_records.length > moving_average_window
        silent_records = silent_records[-moving_average_window..-1] if silent_records.length > moving_average_window
        improvement_records = improvement_records[-moving_average_window..-1] if improvement_records.length > moving_average_window

        change_ma = change_records.count(true).to_f/change_records.length
        silent_ma = silent_records.count(true).to_f/silent_records.length
        improvement_ma = improvement_records.count(true).to_f/improvement_records.length
        # p [change_ma,improvement_ma]

        output_file.puts "#{climb_length*start + step},#{mutation_rate},#{change_ma.round(5)},#{silent_ma.round(5)},#{improvement_ma.round(5)},#{answer_score},#{answer.script.inspect},#{answer_wtf},#{mutant_score},#{mutant.script.inspect},#{mutant_wtf}"
      end
      mutation_rate = (mutation_rate < 0.01 ? 0.5 : (mutation_rate * 0.5))
    end
  end
end