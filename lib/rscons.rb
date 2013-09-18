require "rscons/builder"
require "rscons/cache"
require "rscons/environment"
require "rscons/varset"
require "rscons/version"

require "rscons/monkey/module"
require "rscons/monkey/string"

# default builders
require "rscons/builders/library"
require "rscons/builders/object"
require "rscons/builders/program"

# Namespace module for rscons classes
module Rscons
  DEFAULT_BUILDERS = [
    Library,
    Object,
    Program,
  ]

  class BuildError < Exception
  end

  # Remove all generated files
  def self.clean
    cache = Cache.new
    cache.targets.each do |target|
      FileUtils.rm_f(target)
    end
    Cache.clear
  end
end
