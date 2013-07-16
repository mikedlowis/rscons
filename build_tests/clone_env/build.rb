debug = Rscons::Environment.new do |env|
  env.build_dir('src', 'debug')
  env['CFLAGS'] = '-O2'
  env['CPPFLAGS'] = '-DSTRING="Debug Version"'
  env.Program('program-debug', Dir['src/*.c'])
end

release = debug.clone('CPPFLAGS' => '-DSTRING="Release Version"') do |env|
  env.build_dir('src', 'release')
  env.Program('program-release', Dir['src/*.c'])
end
