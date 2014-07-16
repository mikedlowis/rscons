module Rscons
  module Builders
    # A default Rscons builder that produces a static library archive.
    class SharedLibrary < Builder
      # Return default construction variables for the builder.
      #
      # @param env [Environment] The Environment using the builder.
      #
      # @return [Hash] Default construction variables for the builder.
      def default_variables(env)
        defaults = {
          'SHLD' => nil,
          'SHLDCMD' => ['${SHLD}', '-o', '${_TARGET}', '${SHLDFLAGS}', '${_SOURCES}', '${SHLIBDIRPREFIX}${LIBPATH}', '${SHLIBLINKPREFIX}${LIBS}'],
          'SHLDFLAGS' => [],
          'SHLIBDIRPREFIX' => '-L',
          'SHLIBLINKPREFIX' => '-l',
        }
        # OSX:
        #    gcc -o source/libsof/libsof.os -c -Wall -Werror -std=c99 -fPIC source/libsof/libsof.c
        #    gcc -o build/lib/libsof.dylib -dynamiclib source/libsof/libsof.os -Lbuild/lib
        # Cygwin:
        #
        case Object.const_get("RUBY_PLATFORM")
        when /mingw|cygwin/
          defaults['SHLIBSUFFIX'] = '.dll'
        when /darwin/
          defaults['SHLIBSUFFIX'] = '.dylib'
          defaults['SHLDFLAGS'] += ['-dynamiclib']
        else
          defaults['SHLIBSUFFIX'] = '.so'
        end
        defaults
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
        if objects
          vars = vars.merge({
            '_TARGET' => target,
            '_SOURCES' => objects,
          })
          command = env.build_command("${ARCMD}", vars)
          standard_build("AR #{target}", target, command, objects, env, cache)
        end
      end
    end
  end
end
