require 'set'

module Rscons
  class Environment
    attr_reader :builders

    # Initialize a newly constructed Environment object
    # === Arguments
    # +variables+ _Hash_ ::
    #   the variables hash can contain both construction variables, which are
    #   uppercase strings (such as "CC" or "LDFLAGS"), and rscons options,
    #   which are lowercase symbols (such as :echo).
    def initialize(variables = {})
      @variables = VarSet.new(variables)
      @targets = {}
      @builders = {}
      @variables[:exclude_builders] ||= []
      unless @variables[:exclude_builders] == :all
        exclude_builders = Set.new(@variables[:exclude_builders] || [])
        DEFAULT_BUILDERS.each do |builder_class|
          unless exclude_builders.include?(builder_class.short_name)
            add_builder(builder_class.new(self))
          end
        end
      end
      (@variables[:builders] || []).each do |builder|
        add_builder(builder)
      end
      @variables[:echo] ||= :command

      if block_given?
        yield self
        self.process
      end
    end

    def add_builder(builder)
      @builders[builder.class.short_name] = builder
      var_defs = builder.default_variables(self)
      if var_defs
        var_defs.each_pair do |var, val|
          @variables[var] ||= val
        end
      end
    end

    def [](*args)
      @variables.send(:[], *args)
    end

    def []=(*args)
      @variables.send(:[]=, *args)
    end

    def process
      cache = Cache.new
      targets_processed = Set.new
      process_target = proc do |target|
        sources_built = @targets[target][:source].map do |src|
          targets_processed.include?(src) or not @targets.include?(src) or process_target.call(src)
        end.all?
        if sources_built
          @targets[target][:builder].run(target,
                                         @targets[target][:source],
                                         cache,
                                         *@targets[target][:args])
        else
          false
        end
      end
      @targets.each do |target, info|
        next if targets_processed.include?(target)
        break unless process_target.call(target)
      end
      cache.write
    end

    def execute(short_desc, command, extra_vars)
      merged_variables = @variables.merge(extra_vars)
      expand_varref = proc do |varref|
        if varref.is_a?(Array)
          varref.map do |ent|
            expand_varref.call(ent)
          end
        else
          if varref =~ /^(.*)\$\[(\w+)\](.*)$/
            # expand array with given prefix, suffix
            prefix, varname, suffix = $1, $2, $3
            varval = merged_variables[varname]
            unless varval.is_a?(Array)
              raise "Array expected for $#{varname}"
            end
            varval.map {|e| "#{prefix}#{e}#{suffix}"}
          elsif varref =~ /^\$(.*)$/
            # expand a single variable reference
            varname = $1
            varval = merged_variables[varname]
            varval or raise "Could not find variable #{varname.inspect}"
            expand_varref.call(varval)
          else
            varref
          end
        end
      end
      command = expand_varref.call(command.flatten).flatten
      if @variables[:echo] == :command
        puts command.map { |c| c =~ /\s/ ?  "'#{c}'" : c }.join(' ')
      elsif @variables[:echo] == :short
        puts short_desc
      end
      system(*command)
    end

    alias_method :orig_method_missing, :method_missing
    def method_missing(method, *args)
      if @builders.has_key?(method.to_s)
        target, source, *rest = args
        source = [source] unless source.is_a?(Array)
        @targets[target] = {
          builder: @builders[method.to_s],
          source: source,
          args: rest,
        }
      else
        orig_method_missing(method, *args)
      end
    end

    def parse_makefile_deps(mf_fname, target)
      deps = []
      buildup = ''
      File.read(mf_fname).each_line do |line|
        if line =~ /^(.*)\\\s*$/
          buildup += ' ' + $1
        else
          if line =~ /^(.*): (.*)$/
            target, tdeps = $1.strip, $2
            if target == target
              deps += tdeps.split(' ').map(&:strip)
            end
          end
          buildup = ''
        end
      end
      deps
    end
  end
end
