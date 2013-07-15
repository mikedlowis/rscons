module Rscons
  class Builder
    def initialize(env)
      @env = env
    end
    def default_variables(env)
      {}
    end
    def produces?(target, source)
      false
    end
  end
end
