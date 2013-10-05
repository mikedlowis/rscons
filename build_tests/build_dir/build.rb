Rscons::Environment.new do |env|
  env.append('CPPPATH' => Dir['src/**/*/'])
  env.build_dir(%r{^src/([^/]+)/}, 'build_\\1/')
  env.Program('build_dir', Dir['src/**/*.c'])
end
