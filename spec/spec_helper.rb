require "simplecov"

SimpleCov.start do
  add_filter "/spec/"
  add_filter "/build_tests/"
end

require "rscons"
