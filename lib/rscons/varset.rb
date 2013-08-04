module Rscons
  # This class represents a collection of variables which can be accessed
  # as certain types
  class VarSet
    # The underlying hash
    attr_reader :vars

    # Create a VarSet
    # @param vars [Hash] Optional initial variables.
    def initialize(vars = {})
      @vars = vars
    end

    # Access the value of variable as a particular type
    # @param key [String, Symbol] The variable name.
    # @param type [Symbol, nil] Optional specification of the type desired.
    #   If the variable is a String and type is :array, a 1-element array with
    #   the variable value will be returned. If the variable is an Array and
    #   type is :string, the first element from the variable value will be
    #   returned.
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

    # Assign a value to a variable.
    # @param key [String, Symbol] The variable name.
    # @param val [Object] The value.
    def []=(key, val)
      @vars[key] = val
    end

    # Add or overwrite a set of variables
    # @param values [VarSet, Hash] New set of variables.
    def append(values)
      values = values.vars if values.is_a?(VarSet)
      @vars.merge!(values)
      self
    end

    # Create a new VarSet object based on the first merged with other.
    # @param other [VarSet, Hash] Other variables to add or overwrite.
    def merge(other = {})
      VarSet.new(Marshal.load(Marshal.dump(@vars))).append(other)
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
        if varref =~ /^(.*)\$\[(\w+)\](.*)$/
          # expand array with given prefix, suffix
          prefix, varname, suffix = $1, $2, $3
          varval = expand_varref(@vars[varname])
          unless varval.is_a?(Array)
            raise "Array expected for $#{varname}"
          end
          varval.map {|e| "#{prefix}#{e}#{suffix}"}
        elsif varref =~ /^\$(.*)$/
          # expand a single variable reference
          varname = $1
          varval = expand_varref(@vars[varname])
          varval or raise "Could not find variable #{varname.inspect}"
          expand_varref(varval)
        else
          varref
        end
      end
    end
  end
end
