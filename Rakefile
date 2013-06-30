require "bundler"
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  raise LoadError.new("Unable to setup Bundler; you might need to `bundle install`: #{e.message}")
end

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rake/clean"

CLEAN.include 'build_tests_run'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec
