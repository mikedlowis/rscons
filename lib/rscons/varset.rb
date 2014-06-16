module Rscons
  # This class represents a collection of variables which supports efficient
  # deep cloning.
  class VarSet
    # Create a VarSet.
    #
    # @param vars [Hash] Optional initial variables.
    def initialize(vars = {})
      @my_vars = {}
      @coa_vars = []
      append(vars)
    end

    # Access the value of variable.
    #
    # @param key [String, Symbol] The variable name.
    #
    # @return [Object] The variable's value.
    def [](key)
      if @my_vars.include?(key)
        @my_vars[key]
      else
        @coa_vars.each do |coa_vars|
          if coa_vars.include?(key)
            @my_vars[key] = deep_dup(coa_vars[key])
            return @my_vars[key]
          end
        end
        nil
      end
    end

    # Assign a value to a variable.
    #
    # @param key [String, Symbol] The variable name.
    #
    # @param val [Object] The value to set.
    def []=(key, val)
      @my_vars[key] = val
    end

    # Check if the VarSet contains a variable.
    #
    # @param key [String, Symbol] The variable name.
    #
    # @return [Boolean] Whether the VarSet contains the variable.
    def include?(key)
      if @my_vars.include?(key)
        true
      else
        @coa_vars.find do |coa_vars|
          coa_vars.include?(key)
        end
      end
    end

    # Add or overwrite a set of variables.
    #
    # @param values [VarSet, Hash] New set of variables.
    #
    # @return [self]
    def append(values)
      coa!
      if values.is_a?(VarSet)
        values.send(:coa!)
        @coa_vars = values.instance_variable_get(:@coa_vars) + @coa_vars
      else
        @my_vars = deep_dup(values)
      end
      self
    end

    # Create a new VarSet object based on the first merged with other.
    #
    # @param other [VarSet, Hash] Other variables to add or overwrite.
    #
    # @return [VarSet] The newly created VarSet.
    def merge(other = {})
      coa!
      varset = self.class.new
      varset.instance_variable_set(:@coa_vars, @coa_vars.dup)
      varset.append(other)
    end
    alias_method :clone, :merge

    # Replace "$\{var}" variable references in varref with the expanded
    # variables' values, recursively.
    #
    # @param varref [String, Array] Value containing references to variables.
    #
    # @return [String, Array]
    #   Expanded value with "$\{var}" variable references replaced.
    def expand_varref(varref)
      if varref.is_a?(Array)
        varref.map do |ent|
          expand_varref(ent)
        end.flatten
      else
        if varref =~ /^(.*)\$\{([^}]+)\}(.*)$/
          prefix, varname, suffix = $1, $2, $3
          varval = expand_varref(self[varname])
          if varval.is_a?(String) or varval.nil?
            expand_varref("#{prefix}#{varval}#{suffix}")
          elsif varval.is_a?(Array)
            varval.map {|vv| expand_varref("#{prefix}#{vv}#{suffix}")}.flatten
          else
            raise "I do not know how to expand a variable reference to a #{varval.class.name} (from #{varname.inspect} => #{self[varname].inspect})"
          end
        else
          varref
        end
      end
    end

    private

    # Move all VarSet variables into the copy-on-access list.
    #
    # @return [void]
    def coa!
      unless @my_vars.empty?
        @coa_vars.unshift(@my_vars)
        @my_vars = {}
      end
    end

    # Create a deep copy of an object.
    #
    # Only objects which are of type String, Array, or Hash are deep copied.
    # Any other object just has its referenced copied.
    #
    # @param obj [Object] Object to deep copy.
    #
    # @return [Object] Deep copied value.
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
