module Rscons
  # The BuildTarget class represents a single build target.
  class BuildTarget
    # Create a BuildTarget object.
    #
    # @param env [Environment] The Environment.
    # @param target [String] Name of the target file.
    def initialize(env, target)
      @env = env
      @target = target
    end

    # Manually record a given target as depending on the specified files.
    #
    # @param user_deps [Array<String>] Dependency files.
    def depends(*user_deps)
      @env.depends(@target, *user_deps)
    end

    # Convert the BuildTarget to a String.
    #
    # This method always returns the target file name.
    #
    # @return [String] Target file name.
    def to_s
      @target
    end
  end
end
