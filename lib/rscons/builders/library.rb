require 'fileutils'

module Rscons
  # A default RScons builder that produces a static library archive.
  class Library < Builder
    def default_variables(env)
      {
        'AR' => 'ar',
        'LIBSUFFIX' => '.a',
        'ARFLAGS' => [],
        'ARCOM' => ['$AR', 'rcs', '$ARFLAGS', '$TARGET', '$SOURCES']
      }
    end

    def run(target, sources, cache, env, vars = {})
      # build sources to linkable objects
      objects = env.build_sources(sources, [env['OBJSUFFIX'], env['LIBSUFFIX']].flatten, cache, vars)
      if objects
        vars = vars.merge({
          'TARGET' => target,
          'SOURCES' => objects,
        })
        command = env.build_command(env['ARCOM'], vars)
        unless cache.up_to_date?(target, command, objects)
          FileUtils.rm_f(target)
          return false unless env.execute("AR #{target}", command)
          cache.register_build(target, command, objects)
        end
        target
      end
    end
  end
end
