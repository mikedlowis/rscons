require "simplecov"

SimpleCov.start do
  add_filter "/build_tests/"
  command_name("build_tests")
end

require "rscons"
