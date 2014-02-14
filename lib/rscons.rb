require "rscons/builder"
require "rscons/cache"
require "rscons/environment"
require "rscons/varset"
require "rscons/version"

# default builders
require "rscons/builders/library"
require "rscons/builders/object"
require "rscons/builders/program"

# Namespace module for rscons classes
module Rscons
  DEFAULT_BUILDERS = [
    :Library,
    :Object,
    :Program,
  ]

  class BuildError < RuntimeError; end

  # Remove all generated files
  def self.clean
    cache = Cache.new
    # remove all built files
    cache.targets.each do |target|
      FileUtils.rm_f(target)
    end
    # remove all created directories if they are empty
    cache.directories.sort {|a, b| b.size <=> a.size}.each do |directory|
      next unless File.directory?(directory)
      if (Dir.entries(directory) - ['.', '..']).empty?
        Dir.rmdir(directory) rescue nil
      end
    end
    Cache.clear
  end

  # Return whether the given path is an absolute filesystem path or not
  # @param path [String] the path to examine
  def self.absolute_path?(path)
    path =~ %r{^(/|\w:[\\/])}
  end

  # Return a new path by changing the suffix in path to suffix.
  # @param path [String] the path to alter
  # @param suffix [String] the new filename suffix
  def self.set_suffix(path, suffix)
    path.sub(/\.[^.]*$/, suffix)
  end
end
