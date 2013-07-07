require "rscons/builder"
require "rscons/cache"
require "rscons/environment"
require "rscons/version"

require "rscons/monkey/module"
require "rscons/monkey/string"

# default builders
require "rscons/builders/cc"
require "rscons/builders/program"

module Rscons
  DEFAULT_BUILDERS = [
    CC,
    Program,
  ]
end
