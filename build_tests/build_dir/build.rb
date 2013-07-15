Rscons::Environment.new do |env|
  env.append('CPPPATH' => Dir['src/**/*/'])
  env.build_dir('src', 'build')
  env.Program('build_dir', Dir['src/**/*.c'])
end
