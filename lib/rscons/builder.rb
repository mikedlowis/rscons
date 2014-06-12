require "fileutils"

module Rscons
  # Namespace module in which to store builders for convenient grouping
  module Builders; end

  # Class to hold an object that knows how to build a certain type of file.
  class Builder
    # Return the name of the builder.
    # If not overridden this defaults to the last component of the class name.
    def name
      self.class.name.split(":").last
    end

    # Return a set of default variable values for the Environment to use
    # unless the user overrides any.
    # @param env [Environment] The Environment.
    def default_variables(env)
      {}
    end

    # Create a BuildTarget object for this build target.
    #
    # Builder sub-classes can override this method to manipulate parameters
    # (for example, add a suffix to the user-given target file name).
    #
    # @param env [Environment] The Environment.
    # @param target [String] The user-supplied target name.
    #
    # @return [BuildTarget]
    def create_build_target(env, target)
      BuildTarget.new(env, target)
    end

    # Return whether this builder object is capable of producing a given target
    # file name from a given source file name.
    # @param target [String] The target file name.
    # @param source [String, Array] The source file name(s).
    # @param env [Environment] The Environment.
    def produces?(target, source, env)
      false
    end

    # Check if the cache is up to date for the target and if not execute the
    # build command.
    # Return the name of the target or false on failure.
    def standard_build(short_cmd_string, target, command, sources, env, cache)
      unless cache.up_to_date?(target, command, sources, env)
        cache.mkdir_p(File.dirname(target))
        FileUtils.rm_f(target)
        return false unless env.execute(short_cmd_string, command)
        cache.register_build(target, command, sources, env)
      end
      target
    end
  end
end
