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
      @varset = VarSet.new(variables)
      @targets = {}
      @builders = {}
      @varset[:exclude_builders] ||= []
      unless @varset[:exclude_builders] == :all
        exclude_builders = Set.new(@varset[:exclude_builders] || [])
        DEFAULT_BUILDERS.each do |builder_class|
          unless exclude_builders.include?(builder_class.short_name)
            add_builder(builder_class.new(self))
          end
        end
      end
      (@varset[:builders] || []).each do |builder|
        add_builder(builder)
      end
      @varset[:echo] ||= :command

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
          @varset[var] ||= val
        end
      end
    end

    def [](*args)
      @varset.send(:[], *args)
    end

    def []=(*args)
      @varset.send(:[]=, *args)
    end

    def append(*args)
      @varset.send(:append, *args)
    end

    def process
      cache = Cache.new
      targets_processed = Set.new
      process_target = proc do |target|
        if @targets[target][:source].map do |src|
          targets_processed.include?(src) or not @targets.include?(src) or process_target.call(src)
        end.all?
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

    def build_command(command_template, extra_vars)
      @varset.merge(extra_vars).expand_varref(command_template)
    end

    def execute(short_desc, command)
      if @varset[:echo] == :command
        puts command.map { |c| c =~ /\s/ ?  "'#{c}'" : c }.join(' ')
      elsif @varset[:echo] == :short
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
