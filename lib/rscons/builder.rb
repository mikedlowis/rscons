module Rscons
  # Class to hold an object that knows how to build a certain type of file.
  class Builder
    # Return a set of default variable values for the Environment to use
    # unless the user overrides any.
    # @param env [Environment] The Environment.
    def default_variables(env)
      {}
    end

    # Return whether this builder object is capable of producing a given target
    # file name from a given source file name.
    # @param target [String] The target file name.
    # @param source [String, Array] The source file name(s).
    # @param env [Environment] The Environment.
    def produces?(target, source, env)
      false
    end
  end
end
