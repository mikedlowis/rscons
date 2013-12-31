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
        'LDCMD' => ['${LD}', '-o', '${_TARGET}', '${LDFLAGS}', '${_SOURCES}', '-L${LIBPATH}', '-l${LIBS}']
      }
    end

    def run(target, sources, cache, env, vars)
      # build sources to linkable objects
      objects = env.build_sources(sources, [env['OBJSUFFIX'], env['LIBSUFFIX']].flatten, cache, vars)
      return false unless objects
      ld = if env["LD"]
             env["LD"]
           elsif sources.find {|s| s.has_suffix?(env["DSUFFIX"])}
             env["DC"]
           elsif sources.find {|s| s.has_suffix?(env["CXXSUFFIX"])}
             env["CXX"]
           else
             env["CC"]
           end
      vars = vars.merge({
        '_TARGET' => target,
        '_SOURCES' => objects,
        'LD' => ld,
      })
      command = env.build_command(env['LDCMD'], vars)
      standard_build("LD #{target}", target, command, objects, env, cache)
    end
  end
end
