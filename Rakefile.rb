require "bundler"
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  raise LoadError.new("Unable to setup Bundler; you might need to `bundle install`: #{e.message}")
end

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rake/clean"
require "yard"

CLEAN.include 'build_tests_run'

RSpec::Core::RakeTask.new(:spec) do |task|
  task.rspec_opts = "--default-path spec"
end

RSpec::Core::RakeTask.new(:build_tests) do |task|
  task.rspec_opts = "--default-path build_tests"
  task.pattern = "build_tests/*_spec.rb"
end

YARD::Rake::YardocTask.new do |yard|
  yard.files = ['lib/**/*.rb']
end

task :default => :spec

task :tests => [:spec, :build_tests]
