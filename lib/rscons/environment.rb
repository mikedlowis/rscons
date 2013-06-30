module Rscons
  class Environment
    class << self
      alias_method :orig_new, :new
    end

    def self.new(*args)
      e = Environment.orig_new(*args)
      if block_given?
        yield e
        e.process
      end
      e
    end

    # Initialize a newly constructed Environment object
    # === Arguments
    # +variables+ _Hash_ ::
    #   the variables hash can contain both construction variables, which are
    #   uppercase strings (such as "CC" or "LDFLAGS"), and rscons options,
    #   which are lowercase symbols (such as :echo).
    def initialize(variables = {})
      @variables = variables
    end

    def process
    end
  end
end
