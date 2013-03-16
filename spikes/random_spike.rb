require_relative '../lib/snip'

tokens = [1, 2, 3, 4, 5, "x_1", "x_2", "+", "*", "-", "/", "<", "==", ">"]



100.times do
  random_script = 50.times.inject("") {|script,token| "#{script} #{tokens.sample}"}
  puts Snip::Interpreter.new(script:random_script,bindings:{"x_1" => 2, "x_2" => 3}).run.stack.inspect
end