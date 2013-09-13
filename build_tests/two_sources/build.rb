Rscons::Environment.new(echo: :command) do |env|
  env.Object("one.o", "one.c", 'CPPFLAGS' => ['-DONE'])
  env.Program('two_sources', ['one.o', 'two.c'])
end
