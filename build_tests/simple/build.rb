Rscons::Environment.new do |env|
  # CHANGE FLAGS
  env.Program('simple', Dir['*.c'])
end
