require 'set'
require 'fileutils'

module Rscons
  # The Environment class is the main programmatic interface to Rscons. It
  # contains a collection of construction variables, options, builders, and
  # rules for building targets.
  class Environment
    # Hash of +{"builder_name" => builder_object}+ pairs.
    attr_reader :builders

    # :command, :short, or :off
    attr_accessor :echo

    # String or +nil+
    attr_reader :build_root
    def build_root=(build_root)
      @build_root = build_root
      @build_root.gsub!('\\', '/') if @build_root
    end

    # Create an Environment object.
    # @param options [Hash]
    # Possible options keys:
    #   :echo => :command, :short, or :off (default :short)
    #   :build_root => String specifying build root directory (default nil)
    #   :exclude_builders => true to omit adding default builders (default false)
    # If a block is given, the Environment object is yielded to the block and
    # when the block returns, the {#process} method is automatically called.
    def initialize(options = {})
      @varset = VarSet.new
      @targets = {}
      @user_deps = {}
      @builders = {}
      @build_dirs = []
      @build_hooks = []
      unless options[:exclude_builders]
        DEFAULT_BUILDERS.each do |builder_class_name|
          builder_class = Builders.const_get(builder_class_name)
          builder_class or raise "Could not find builder class #{builder_class_name}"
          add_builder(builder_class.new)
        end
      end
      @echo = options[:echo] || :short
      @build_root = options[:build_root]

      if block_given?
        yield self
        self.process
      end
    end

    # Make a copy of the Environment object.
    #
    # By default, a cloned environment will contain a copy of all environment
    # options, construction variables, and builders, but not a copy of the
    # targets, build hooks, build directories, or the build root.
    #
    # Exactly which items are cloned are controllable via the optional :clone
    # parameter, which can be :none, :all, or a set or array of any of the
    # following:
    # - :variables to clone construction variables (on by default)
    # - :builders to clone the builders (on by default)
    # - :build_root to clone the build root (off by default)
    # - :build_dirs to clone the build directories (off by default)
    # - :build_hooks to clone the build hooks (off by default)
    #
    # If a block is given, the Environment object is yielded to the block and
    # when the block returns, the {#process} method is automatically called.
    #
    # Any options that #initialize receives can also be specified here.
    #
    # @return a new {Environment} object.
    def clone(options = {})
      clone = options[:clone] || Set[:variables, :builders]
      clone = Set[:variables, :builders, :build_root, :build_dirs, :build_hooks] if clone == :all
      clone = Set[] if clone == :none
      clone = Set.new(clone) if clone.is_a?(Array)
      clone.delete(:builders) if options[:exclude_builders]
      env = self.class.new(
        echo: options[:echo] || @echo,
        build_root: options[:build_root],
        exclude_builders: true)
      if clone.include?(:builders)
        @builders.each do |builder_name, builder|
          env.add_builder(builder)
        end
      end
      env.append(@varset) if clone.include?(:variables)
      env.build_root = @build_root if clone.include?(:build_root)
      if clone.include?(:build_dirs)
        @build_dirs.each do |src_dir, obj_dir|
          env.build_dir(src_dir, obj_dir)
        end
      end
      if clone.include?(:build_hooks)
        @build_hooks.each do |build_hook_block|
          env.add_build_hook(&build_hook_block)
        end
      end

      if block_given?
        yield env
        env.process
      end
      env
    end

    # Add a {Builder} object to the Environment.
    def add_builder(builder)
      @builders[builder.name] = builder
      var_defs = builder.default_variables(self)
      if var_defs
        var_defs.each_pair do |var, val|
          @varset[var] ||= val
        end
      end
    end

    # Add a build hook to the Environment.
    def add_build_hook(&block)
      @build_hooks << block
    end

    # Specify a build directory for this Environment.
    # Source files from src_dir will produce object files under obj_dir.
    def build_dir(src_dir, obj_dir)
      src_dir = src_dir.gsub('\\', '/') if src_dir.is_a?(String)
      @build_dirs << [src_dir, obj_dir]
    end

    # Return the file name to be built from source_fname with suffix suffix.
    # This method takes into account the Environment's build directories.
    def get_build_fname(source_fname, suffix)
      build_fname = Rscons.set_suffix(source_fname, suffix).gsub('\\', '/')
      found_match = @build_dirs.find do |src_dir, obj_dir|
        if src_dir.is_a?(Regexp)
          build_fname.sub!(src_dir, obj_dir)
        else
          build_fname.sub!(%r{^#{src_dir}/}, "#{obj_dir}/")
        end
      end
      if @build_root and not found_match
        unless Rscons.absolute_path?(source_fname) or build_fname.start_with?("#{@build_root}/")
          build_fname = "#{@build_root}/#{build_fname}"
        end
      end
      build_fname.gsub!('\\', '/')
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
      @varset.append(*args)
    end

    # Build all target specified in the Environment.
    # When a block is passed to Environment.new, this method is automatically
    # called after the block returns.
    def process
      clean_target_paths!
      cache = Cache.instance
      cache.clear_checksum_cache!
      targets_processed = {}
      process_target = proc do |target|
        targets_processed[target] ||= begin
          @targets[target][:sources].each do |src|
            if @targets.include?(src) and not targets_processed.include?(src)
              process_target.call(src)
            end
          end
          result = run_builder(@targets[target][:builder],
                               target,
                               @targets[target][:sources],
                               cache,
                               @targets[target][:vars] || {})
          unless result
            cache.write
            raise BuildError.new("Failed to build #{target}")
          end
          result
        end
      end
      @targets.each do |target, target_params|
        process_target.call(target)
      end
      cache.write
    end

    # Clear all targets registered for the Environment.
    def clear_targets
      @targets = {}
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

    # Expand a construction variable reference (String or Array)
    def expand_varref(varref)
      @varset.expand_varref(varref)
    end

    # Execute a builder command
    # @param short_desc [String] Message to print if the Environment's echo
    #   mode is set to :short
    # @param command [Array] The command to execute.
    # @param options [Hash] Optional options, possible keys:
    #   - :env - environment Hash to pass to Kernel#system.
    #   - :options - options Hash to pass to Kernel#system.
    def execute(short_desc, command, options = {})
      print_command = proc do
        puts command.map { |c| c =~ /\s/ ? "'#{c}'" : c }.join(' ')
      end
      if @echo == :command
        print_command.call
      elsif @echo == :short
        puts short_desc
      end
      env_args = options[:env] ? [options[:env]] : []
      options_args = options[:options] ? [options[:options]] : []
      system(*env_args, *command, *options_args).tap do |result|
        unless result or @echo == :command
          $stdout.write "Failed command was: "
          print_command.call
        end
      end
    end

    def method_missing(method, *args)
      if @builders.has_key?(method.to_s)
        target, sources, vars, *rest = args
        unless vars.nil? or vars.is_a?(Hash) or vars.is_a?(VarSet)
          raise "Unexpected construction variable set: #{vars.inspect}"
        end
        sources = [sources] unless sources.is_a?(Array)
        add_target(target, @builders[method.to_s], sources, vars, rest)
      else
        super
      end
    end

    def add_target(target, builder, sources, vars, args)
      @targets[target] = {
        builder: builder,
        sources: sources,
        vars: vars,
        args: args,
      }
    end

    # Manually record a given target as depending on the specified
    # dependency files.
    def depends(target, *user_deps)
      @user_deps[target] ||= []
      @user_deps[target] = (@user_deps[target] + user_deps).uniq
    end

    # Return the list of user dependencies for a given target, or +nil+ for
    # none.
    def get_user_deps(target)
      @user_deps[target]
    end

    # Build a list of source files into files containing one of the suffixes
    # given by suffixes.
    # This method is used internally by Rscons builders.
    # @param sources [Array] List of source files to build.
    # @param suffixes [Array] List of suffixes to try to convert source files into.
    # @param cache [Cache] The Cache.
    # @param vars [Hash] Extra variables to pass to the builder.
    # Return a list of the converted file names.
    def build_sources(sources, suffixes, cache, vars)
      sources.map do |source|
        if source.end_with?(*suffixes)
          source
        else
          converted = nil
          suffixes.each do |suffix|
            converted_fname = get_build_fname(source, suffix)
            builder = @builders.values.find { |b| b.produces?(converted_fname, source, self) }
            if builder
              converted = run_builder(builder, converted_fname, [source], cache, vars)
              return nil unless converted
              break
            end
          end
          converted or raise "Could not find a builder to handle #{source.inspect}."
        end
      end
    end

    # Invoke a builder to build the given target based on the given sources.
    # @param builder [Builder] The Builder to use.
    # @param target [String] The target output file.
    # @param sources [Array] List of source files.
    # @param cache [Cache] The Cache.
    # @param vars [Hash] Extra variables to pass to the builder.
    # Return the result of the builder's run() method.
    def run_builder(builder, target, sources, cache, vars)
      vars = @varset.merge(vars)
      @build_hooks.each do |build_hook_block|
        build_operation = {
          builder: builder,
          target: target,
          sources: sources,
          vars: vars,
          env: self,
        }
        build_hook_block.call(build_operation)
      end
      builder.run(target, sources, cache, self, vars)
    end

    private

    # Expand all target paths that begin with ^/ to be relative to the
    # Environment's build root, if present
    def clean_target_paths!
      if @build_root
        expand = lambda do |path|
          path.sub(%r{^\^(?=[\\/])}, @build_root)
        end

        new_targets = {}
        @targets.each_pair do |target, target_params|
          target_params[:sources].map! do |source|
            expand[source]
          end
          new_targets[expand[target]] = target_params
        end
        @targets = new_targets
      end
    end

    # Parse dependencies for a given target from a Makefile.
    # This method is used internally by Rscons builders.
    # @param mf_fname [String] File name of the Makefile to read.
    # @param target [String] Name of the target to gather dependencies for.
    def self.parse_makefile_deps(mf_fname, target)
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
  end
end
