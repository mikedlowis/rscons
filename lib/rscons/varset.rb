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

    def append(values)
      values = values.vars if values.is_a?(VarSet)
      @vars.merge!(values)
      self
    end

    def merge(other = {})
      VarSet.new(Marshal.load(Marshal.dump(@vars))).append(other)
    end
    alias_method :clone, :merge

    def expand_varref(varref)
      if varref.is_a?(Array)
        varref.map do |ent|
          expand_varref(ent)
        end.flatten
      else
        if varref =~ /^(.*)\$\[(\w+)\](.*)$/
          # expand array with given prefix, suffix
          prefix, varname, suffix = $1, $2, $3
          varval = @vars[varname]
          unless varval.is_a?(Array)
            raise "Array expected for $#{varname}"
          end
          varval.map {|e| "#{prefix}#{e}#{suffix}"}
        elsif varref =~ /^\$(.*)$/
          # expand a single variable reference
          varname = $1
          varval = @vars[varname]
          varval or raise "Could not find variable #{varname.inspect}"
          expand_varref(varval)
        else
          varref
        end
      end
    end
  end
end
