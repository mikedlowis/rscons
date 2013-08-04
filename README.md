# Rscons

Software construction library inspired by SCons and implemented in Ruby

## Installation

Add this line to your application's Gemfile:

    gem 'rscons'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rscons

## Usage

    RScons::Environment.new do |env|
      env.Program('program', Dir['*.c'])
    end

    main_env = RScons::Environment.new do |env|
      env.build_dir('src', 'build/main')
      env.Program('program', Dir['src/**/*.cc'])
    end

    debug_env = main_env.clone do |env|
      env.build_dir('src', 'build/debug')
      env['CFLAGS'] = ['-g', '-O0']
      env.Program('program-debug', Dir['src/**/*.cc'])
    end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
