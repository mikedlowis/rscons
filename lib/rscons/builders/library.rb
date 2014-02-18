module Rscons
  module Builders
    # A default Rscons builder that produces a static library archive.
    class Rscons::Builders::Library < Rscons::Builder
      def default_variables(env)
        {
          'AR' => 'ar',
          'LIBSUFFIX' => '.a',
          'ARFLAGS' => [],
          'ARCMD' => ['${AR}', 'rcs', '${ARFLAGS}', '${_TARGET}', '${_SOURCES}']
        }
      end

      def run(target, sources, cache, env, vars)
        # build sources to linkable objects
        objects = env.build_sources(sources, [env['OBJSUFFIX'], env['LIBSUFFIX']].flatten, cache, vars)
        if objects
          vars = vars.merge({
            '_TARGET' => target,
            '_SOURCES' => objects,
          })
          command = env.build_command(env['ARCMD'], vars)
          standard_build("AR #{target}", target, command, objects, env, cache)
        end
      end
    end
  end
end
