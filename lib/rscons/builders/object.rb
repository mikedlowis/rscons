module Rscons
  class Object < Builder
    def default_variables(env)
      {
        'OBJSUFFIX' => '.o',

        'AS' => 'gcc',
        'ASFLAGS' => [],
        'ASSUFFIX' => '.S',
        'ASPPPATH' => '$CPPPATH',
        'ASPPFLAGS' => '$CPPFLAGS',
        'ASDEPGEN' => ['-MMD', '-MF', '$DEPFILE'],
        'ASCOM' => ['$AS', '-c', '-o', '$TARGET', '$ASDEPGEN', '-I$[ASPPPATH]', '$ASPPFLAGS', '$ASFLAGS', '$SOURCES'],

        'CC' => 'gcc',
        'CFLAGS' => [],
        'CPPFLAGS' => [],
        'CPPPATH' => [],
        'CSUFFIX' => '.c',
        'CCDEPGEN' => ['-MMD', '-MF', '$DEPFILE'],
        'CCCOM' => ['$CC', '-c', '-o', '$TARGET', '$CCDEPGEN', '-I$[CPPPATH]', '$CPPFLAGS', '$CFLAGS', '$SOURCES'],
      }
    end

    def produces?(target, source, env)
      target.has_suffix?(env['OBJSUFFIX']) and (
        source.has_suffix?(env['ASSUFFIX']) or
        source.has_suffix?(env['CSUFFIX']))
    end

    def run(target, sources, cache, env)
      vars = {
        'TARGET' => target,
        'SOURCES' => sources,
        'DEPFILE' => target.set_suffix('.mf'),
      }
      com_prefix = if sources.first.has_suffix?(env['ASSUFFIX'])
                     'AS'
                   elsif sources.first.has_suffix?(env['CSUFFIX'])
                     'CC'
                   else
                     raise "Error: unknown input file type: #{sources.first.inspect}"
                   end
      command = env.build_command(env["#{com_prefix}COM"], vars)
      unless cache.up_to_date?(target, command, sources)
        return false unless env.execute("#{com_prefix} #{target}", command)
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
