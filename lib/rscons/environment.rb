require 'set'
require 'fileutils'

module Rscons
  # The Environment class is the main programmatic interface to RScons. It
  # contains a collection of construction variables, options, builders, and
  # rules for building targets.
  class Environment
    # [Array] of {Builder} objects.
    attr_reader :builders

    # Create an Environment object.
    # @param variables [Hash]
    #   The variables hash can contain construction variables, which are
    #   uppercase strings (such as "CC" or "LDFLAGS"), user variables, which
    #   are lowercase strings (such as "sources"), and RScons options, which
    #   are lowercase symbols (such as :echo).
    # If a block is given, the Environment object is yielded to the block and
    # when the block returns, the {#process} method is automatically called.
    def initialize(variables = {})
      @varset = VarSet.new(variables)
      @targets = {}
      @builders = {}
      @build_dirs = []
      @varset[:exclude_builders] ||= []
      unless @varset[:exclude_builders] == :all
        exclude_builders = Set.new(@varset[:exclude_builders] || [])
        DEFAULT_BUILDERS.each do |builder_class|
          unless exclude_builders.include?(builder_class.short_name)
            add_builder(builder_class.new)
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

    # Make a copy of the Environment object.
    # The cloned environment will contain a copy of all environment options,
    # construction variables, builders, and build directories. It will not
    # contain a copy of the targets.
    # If a block is given, the Environment object is yielded to the block and
    # when the block returns, the {#process} method is automatically called.
    def clone(variables = {})
      env = Environment.new()
      @builders.each do |builder_name, builder|
        env.add_builder(builder)
      end
      env.append(@varset)
      env.append(variables)

      if block_given?
        yield env
        env.process
      end
      env
    end

    # Add a {Builder} object to the Environment.
    def add_builder(builder)
      @builders[builder.class.short_name] = builder
      var_defs = builder.default_variables(self)
      if var_defs
        var_defs.each_pair do |var, val|
          @varset[var] ||= val
        end
      end
    end

    # Specify a build directory for this Environment.
    # Source files from src_dir will produce object files under obj_dir.
    def build_dir(src_dir, obj_dir)
      src_dir = src_dir.gsub('\\', '/') if src_dir.is_a?(String)
      obj_dir = obj_dir.gsub('\\', '/')
      @build_dirs << [src_dir, obj_dir]
    end

    # Return the file name to be built from source_fname with suffix suffix.
    # This method takes into account the Environment's build directories.
    # It also creates any parent directories needed to be able to open and
    # write to the output file.
    def get_build_fname(source_fname, suffix)
      build_fname = source_fname.set_suffix(suffix).gsub('\\', '/')
      @build_dirs.each do |src_dir, obj_dir|
        if src_dir.is_a?(Regexp)
          build_fname.sub!(src_dir, obj_dir)
        else
          build_fname.sub!(/^#{src_dir}\//, "#{obj_dir}/")
        end
        build_fname.gsub!('\\', '/')
      end
      FileUtils.mkdir_p(File.dirname(build_fname))
      build_fname
    end

    # Access a construction variable or environment option.
    # @see VarSet#[]
    def [](*args)
      @varset.send(:[], *args)
    end

    # Set a construction variable or environment option.
    # @see VarSet#[]=
    def []=(*args)
      @varset.send(:[]=, *args)
    end

    # Add a set of construction variables or environment options.
    # @see VarSet#append
    def append(*args)
      @varset.send(:append, *args)
    end

    # Return a list of target file names
    def targets
      @targets.keys
    end

    # Return a list of sources needed to build target target.
    def target_sources(target)
      @targets[target][:source] rescue nil
    end

    # Build all target specified in the Environment.
    # When a block is passed to Environment.new, this method is automatically
    # called after the block returns.
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
                                         self,
                                         @targets[target][:vars] || {})
        else
          false
        end
      end
      @targets.each do |target, info|
        next if targets_processed.include?(target)
        unless process_target.call(target)
          cache.write
          raise BuildError.new("Failed to build #{target}")
        end
      end
      cache.write
    end

    # Build a command line from the given template, resolving references to
    # variables using the Environment's construction variables and any extra
    # variables specified.
    # @param command_template [Array] template for the command with variable
    #   references
    # @param extra_vars [Hash, VarSet] extra variables to use in addition to
    #   (or replace) the Environment's construction variables when building
    #   the command
    def build_command(command_template, extra_vars)
      @varset.merge(extra_vars).expand_varref(command_template)
    end

    # Execute a builder command
    # @param short_desc [String] Message to print if the Environment's :echo
    #   mode is set to :short
    # @param command [Array] The command to execute.
    # @param options [Hash] Optional options to pass to {Kernel#system}.
    def execute(short_desc, command, options = {})
      print_command = proc do
        puts command.map { |c| c =~ /\s/ ? "'#{c}'" : c }.join(' ')
      end
      if @varset[:echo] == :command
        print_command.call
      elsif @varset[:echo] == :short
        puts short_desc
      end
      system(*command, options).tap do |result|
        unless result or @varset[:echo] == :command
          $stdout.write "Failed command was: "
          print_command.call
        end
      end
    end

    alias_method :orig_method_missing, :method_missing
    def method_missing(method, *args)
      if @builders.has_key?(method.to_s)
        target, source, vars, *rest = args
        unless vars.nil? or vars.is_a?(Hash) or vars.is_a?(VarSet)
          raise "Unexpected construction variable set: #{vars.inspect}"
        end
        source = [source] unless source.is_a?(Array)
        @targets[target] = {
          builder: @builders[method.to_s],
          source: source,
          vars: vars,
          args: rest,
        }
      else
        orig_method_missing(method, *args)
      end
    end

    # Parse dependencies for a given target from a Makefile.
    # This method is used internally by RScons builders.
    # @param mf_fname [String] File name of the Makefile to read.
    # @param target [String] Name of the target to gather dependencies for.
    def parse_makefile_deps(mf_fname, target)
      deps = []
      buildup = ''
      File.read(mf_fname).each_line do |line|
        if line =~ /^(.*)\\\s*$/
          buildup += ' ' + $1
        else
          buildup += ' ' + line
          if buildup =~ /^(.*): (.*)$/
            mf_target, mf_deps = $1.strip, $2
            if mf_target == target
              deps += mf_deps.split(' ').map(&:strip)
            end
          end
          buildup = ''
        end
      end
      deps
    end

    # Build a list of source files into files containing one of the suffixes
    # given by suffixes.
    # This method is used internally by RScons builders.
    # @param sources [Array] List of source files to build.
    # @param suffixes [Array] List of suffixes to try to convert source files into.
    # @param cache [Cache] The Cache.
    # Return a list of the converted file names.
    def build_sources(sources, suffixes, cache, vars = {})
      sources.map do |source|
        if source.has_suffix?(suffixes)
          source
        else
          converted = nil
          suffixes.each do |suffix|
            converted_fname = get_build_fname(source, suffix)
            builder = @builders.values.find { |b| b.produces?(converted_fname, source, self) }
            if builder
              converted = builder.run(converted_fname, [source], cache, self, vars)
              return nil unless converted
              break
            end
          end
          converted or raise "Could not find a builder to handle #{source.inspect}."
        end
      end
    end
  end
end
