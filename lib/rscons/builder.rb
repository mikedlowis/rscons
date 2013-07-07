module Rscons
  class Builder
    def initialize(env)
      @env = env
    end
    def default_variables(env)
      {}
    end
  end
end
