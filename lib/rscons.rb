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
end
