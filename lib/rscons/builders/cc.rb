module Rscons
  class CC < Builder
    def default_variables(env)
      {
        'CC' => 'gcc',
        'CFLAGS' => [],
        'CPPFLAGS' => [],
        'CPPPATH' => [],
        'OBJSUFFIX' => '.o',
        'CSUFFIX' => '.c',
        'CCDEPGEN' => ['-MMD', '-MF', '$DEPFILE'],
        'CCCOM' => ['$CC', '-c', '-o', '$TARGET', '$CCDEPGEN', '-I$[CPPPATH]', '$CPPFLAGS', '$CFLAGS', '$SOURCES']
      }
    end

    def produces?(target, source, env)
      target.has_suffix?(env['OBJSUFFIX']) and source.has_suffix?(env['CSUFFIX'])
    end

    def run(target, sources, cache, env)
      vars = {
        'TARGET' => target,
        'SOURCES' => sources,
        'DEPFILE' => target.set_suffix('.mf'),
      }
      command = env.build_command(env['CCCOM'], vars)
      unless cache.up_to_date?(target, command, sources)
        return false unless env.execute("CC #{target}", command)
        deps = sources
        if File.exists?(vars['DEPFILE'])
          deps += env.parse_makefile_deps(vars['DEPFILE'], target)
          FileUtils.rm_f(vars['DEPFILE'])
        end
        cache.register_build(target, command, deps.uniq)
      end
      target
    end
  end
end
