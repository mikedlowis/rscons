module Rscons
  class CC < Builder
    def default_variables(env)
      {
        'CC' => 'gcc',
        'CFLAGS' => [],
        'CPPFLAGS' => [],
        'OBJSUFFIX' => '.o',
        'CSUFFIX' => '.c',
        'CCDEPGEN' => ['-MMD', '-MF', '$DEPFILE'],
        'CCCOM' => ['$CC', '-c', '-o', '$TARGET', '$CCDEPGEN', '$CPPFLAGS', '$CFLAGS', '$SOURCES']
      }
    end

    def produces?(target, source)
      target.has_suffix?(@env['OBJSUFFIX']) and source.has_suffix?(@env['CSUFFIX'])
    end

    def run(target, sources, cache)
      unless cache.up_to_date?(target, sources)
        vars = {
          'TARGET' => target,
          'SOURCES' => sources,
          'DEPFILE' => target.set_suffix('.mf'),
        }
        @env.execute("CC #{target}", @env['CCCOM'], vars)
        deps = sources
        if File.exists?(vars['DEPFILE'])
          deps += @env.parse_makefile_deps(vars['DEPFILE'], target)
          FileUtils.rm_f(vars['DEPFILE'])
        end
        cache.register_build(target, deps.uniq)
      end
      target
    end
  end
end
