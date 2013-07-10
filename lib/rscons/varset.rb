module Rscons
  class VarSet
    attr_reader :vars

    def initialize(vars = {})
      @vars = vars
    end

    def [](key, type = nil)
      val = @vars[key]
      if type == :array and val.is_a?(String)
        [val]
      elsif type == :string and val.is_a?(Array)
        val.first
      else
        val
      end
    end

    def []=(key, val)
      @vars[key] = val
    end

    def merge(other)
      other = other.vars if other.is_a?(VarSet)
      VarSet.new(@vars.merge(other))
    end
  end
end
