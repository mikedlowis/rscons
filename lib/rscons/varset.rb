module Rscons
  # This class represents a collection of variables which can be accessed
  # as certain types
  class VarSet
    # The underlying hash
    attr_reader :vars

    # Create a VarSet
    # @param vars [Hash] Optional initial variables.
    def initialize(vars = {})
      if vars.is_a?(VarSet)
        @vars = vars.clone.vars
      else
        @vars = vars
      end
    end

    # Access the value of variable as a particular type
    # @param key [String, Symbol] The variable name.
    # @return [Object] The variable's value.
    def [](key)
      @vars[key]
    end

    # Assign a value to a variable.
    # @param key [String, Symbol] The variable name.
    # @param val [Object] The value to set.
    def []=(key, val)
      @vars[key] = val
    end

    # Check if the VarSet contains a variable.
    # @param key [String, Symbol] The variable name.
    # @return [true, false] Whether the VarSet contains a variable.
    def include?(key)
      @vars.include?(key)
    end

    # Add or overwrite a set of variables
    # @param values [VarSet, Hash] New set of variables.
    def append(values)
      values = values.vars if values.is_a?(VarSet)
      @vars.merge!(deep_dup(values))
      self
    end

    # Create a new VarSet object based on the first merged with other.
    # @param other [VarSet, Hash] Other variables to add or overwrite.
    def merge(other = {})
      VarSet.new(deep_dup(@vars)).append(other)
    end
    alias_method :clone, :merge

    # Replace "$" variable references in varref with the variables values,
    # recursively.
    # @param varref [String, Array] Value containing references to variables.
    def expand_varref(varref)
      if varref.is_a?(Array)
        varref.map do |ent|
          expand_varref(ent)
        end.flatten
      else
        if varref =~ /^(.*)\$\{([^}]+)\}(.*)$/
          prefix, varname, suffix = $1, $2, $3
          varval = expand_varref(@vars[varname])
          if varval.is_a?(String)
            expand_varref("#{prefix}#{varval}#{suffix}")
          elsif varval.is_a?(Array)
            varval.map {|vv| expand_varref("#{prefix}#{vv}#{suffix}")}.flatten
          else
            raise "I do not know how to expand a variable reference to a #{varval.class.name} (from #{varname.inspect} => #{@vars[varname].inspect})"
          end
        else
          varref
        end
      end
    end

    private

    # Create a deep copy of a Hash or Array.
    # @param obj [Hash, Array] Hash or Array to deep copy.
    # @return [Hash, Array] Deep copied value.
    def deep_dup(obj)
      obj_class = obj.class
      if obj_class == Hash
        obj.reduce({}) do |result, (k, v)|
          result[k] = deep_dup(v)
          result
        end
      elsif obj_class == Array
        obj.map { |v| deep_dup(v) }
      elsif obj_class == String
        obj.dup
      else
        obj
      end
    end
  end
end
