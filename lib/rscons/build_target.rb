module Rscons
  # The BuildTarget class represents a single build target.
  class BuildTarget
    # Create a BuildTarget object.
    #
    # @param options [Hash] Options to create the BuildTarget with.
    # @option options [Environment] :env
    #   The Environment.
    # @option options [String] :target
    #   The user-supplied target name.
    # @option options [Array<String>] :sources
    #   The user-supplied source file name(s).
    def initialize(options)
      @env = options[:env]
      @target = options[:target]
    end

    # Manually record a given target as depending on the specified files.
    #
    # @param user_deps [Array<String>] Dependency files.
    #
    # @return [void]
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
