module Rscons
  module Builders
    # A default Rscons builder that knows how to link object files into an
    # executable program.
    class Program < Builder
      # Return default construction variables for the builder.
      #
      # @param env [Environment] The Environment using the builder.
      #
      # @return [Hash] Default construction variables for the builder.
      def default_variables(env)
        {
          'OBJSUFFIX' => '.o',
          'PROGSUFFIX' => (Object.const_get("RUBY_PLATFORM") =~ /mingw|cygwin/ ? ".exe" : ""),
          'LD' => nil,
          'LIBSUFFIX' => '.a',
          'LDFLAGS' => [],
          'LIBPATH' => [],
          'LIBDIRPREFIX' => '-L',
          'LIBLINKPREFIX' => '-l',
          'LIBS' => [],
          'LDCMD' => ['${LD}', '-o', '${_TARGET}', '${LDFLAGS}', '${_SOURCES}', '${LIBDIRPREFIX}${LIBPATH}', '${LIBLINKPREFIX}${LIBS}']
        }
      end

      # Create a BuildTarget object for this build target.
      #
      # The build target filename is given a ".exe" suffix if Rscons is
      # executing on a Windows platform and no other suffix is given.
      #
      # @param options [Hash] Options to create the BuildTarget with.
      # @option options [Environment] :env
      #   The Environment.
      # @option options [String] :target
      #   The user-supplied target name.
      # @option options [Array<String>] :sources
      #   The user-supplied source file name(s).
      #
      # @return [BuildTarget]
      def create_build_target(options)
        my_options = options.dup
        unless my_options[:target] =~ /\./
          my_options[:target] += options[:env].expand_varref("${PROGSUFFIX}")
        end
        super(my_options)
      end

      # Run the builder to produce a build target.
      #
      # @param target [String] Target file name.
      # @param sources [Array<String>] Source file name(s).
      # @param cache [Cache] The Cache object.
      # @param env [Environment] The Environment executing the builder.
      # @param vars [Hash,VarSet] Extra construction variables.
      #
      # @return [String,false]
      #   Name of the target file on success or false on failure.
      def run(target, sources, cache, env, vars)
        # build sources to linkable objects
        objects = env.build_sources(sources, env.expand_varref(["${OBJSUFFIX}", "${LIBSUFFIX}"], vars).flatten, cache, vars)
        return false unless objects
        ld = env.expand_varref("${LD}", vars)
        ld = if ld != ""
               ld
             elsif sources.find {|s| s.end_with?(*env.expand_varref("${DSUFFIX}", vars))}
               "${DC}"
             elsif sources.find {|s| s.end_with?(*env.expand_varref("${CXXSUFFIX}", vars))}
               "${CXX}"
             else
               "${CC}"
             end
        vars = vars.merge({
          '_TARGET' => target,
          '_SOURCES' => objects,
          'LD' => ld,
        })
        command = env.build_command("${LDCMD}", vars)
        standard_build("LD #{target}", target, command, objects, env, cache)
      end
    end
  end
end
