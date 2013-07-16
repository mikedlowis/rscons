module Rscons
  class Builder
    def default_variables(env)
      {}
    end
    def produces?(target, source, env)
      false
    end
  end
end
