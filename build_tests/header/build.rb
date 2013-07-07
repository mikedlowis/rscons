Rscons::Environment.new(echo: :short) do |env|
  env.Program('header', Dir['*.c'])
end
