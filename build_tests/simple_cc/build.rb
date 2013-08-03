Rscons::Environment.new do |env|
  # CHANGE FLAGS
  env.Program('simple', Dir['*.cc'])
end
