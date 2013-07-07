Rscons::Environment.new do |env|
  env.Program('header', Dir['*.c'])
end
