# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rscons/version'

Gem::Specification.new do |gem|
  gem.name          = "rscons"
  gem.version       = Rscons::VERSION
  gem.authors       = ["Josh Holtrop"]
  gem.email         = ["jholtrop@gmail.com"]
  gem.description   = %q{Software construction library inspired by SCons and implemented in Ruby}
  gem.summary       = %q{Software construction library inspired by SCons and implemented in Ruby}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
