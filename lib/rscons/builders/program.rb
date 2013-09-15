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

    def run(target, sources, cache, env, vars = {})
      # build sources to linkable objects
      objects = env.build_sources(sources, [env['OBJSUFFIX'], env['LIBSUFFIX']].flatten, cache, vars)
      if objects
        use_cxx = sources.map do |s|
          s.has_suffix?(env['CXXSUFFIX'])
        end.any?
        ld_alt = use_cxx ? env['CXX'] : env['CC']
        vars = vars.merge({
          'TARGET' => target,
          'SOURCES' => objects,
          'LD' => env['LD'] || ld_alt,
        })
        command = env.build_command(env['LDCOM'], vars)
        standard_build("LD #{target}", target, command, objects, env, cache)
      end
    end
  end
end
