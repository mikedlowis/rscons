module Rscons
  # A default RScons builder that knows how to link object files into an
  # executable program.
  class Program < Builder
    def default_variables(env)
      {
        'LD' => nil,
        'OBJSUFFIX' => '.o',
        'LIBSUFFIX' => '.a',
        'LDFLAGS' => [],
        'LIBPATH' => [],
        'LIBS' => [],
        'LDCOM' => ['$LD', '-o', '$TARGET', '$LDFLAGS', '$SOURCES', '-L$[LIBPATH]', '-l$[LIBS]']
      }
    end

    def run(target, sources, cache, env)
      # build sources to linkable objects
      objects = env.build_sources(sources, [env['OBJSUFFIX'], env['LIBSUFFIX']].flatten, cache)
      if objects
        use_cxx = sources.map do |s|
          s.has_suffix?(env['CXXSUFFIX'])
        end.any?
        ld_alt = use_cxx ? env['CXX'] : env['CC']
        vars = {
          'TARGET' => target,
          'SOURCES' => objects,
          'LD' => env['LD'] || ld_alt,
        }
        command = env.build_command(env['LDCOM'], vars)
        unless cache.up_to_date?(target, command, objects)
          return false unless env.execute("LD #{target}", command)
          cache.register_build(target, command, objects)
        end
        target
      end
    end
  end
end
