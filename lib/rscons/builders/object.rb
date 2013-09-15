module Rscons
  # A default RScons builder which knows how to produce an object file from
  # various types of source files.
  class Object < Builder
    def default_variables(env)
      {
        'OBJSUFFIX' => '.o',

        'AS' => '$CC',
        'ASFLAGS' => [],
        'ASSUFFIX' => '.S',
        'ASPPPATH' => '$CPPPATH',
        'ASPPFLAGS' => '$CPPFLAGS',
        'ASDEPGEN' => ['-MMD', '-MF', '$DEPFILE'],
        'ASCOM' => ['$AS', '-c', '-o', '$TARGET', '$ASDEPGEN', '-I$[ASPPPATH]', '$ASPPFLAGS', '$ASFLAGS', '$SOURCES'],

        'CPPFLAGS' => [],
        'CPPPATH' => [],

        'CC' => 'gcc',
        'CFLAGS' => [],
        'CSUFFIX' => '.c',
        'CCDEPGEN' => ['-MMD', '-MF', '$DEPFILE'],
        'CCCOM' => ['$CC', '-c', '-o', '$TARGET', '$CCDEPGEN', '-I$[CPPPATH]', '$CPPFLAGS', '$CFLAGS', '$SOURCES'],

        'CXX' => 'g++',
        'CXXFLAGS' => [],
        'CXXSUFFIX' => '.cc',
        'CXXDEPGEN' => ['-MMD', '-MF', '$DEPFILE'],
        'CXXCOM' =>['$CXX', '-c', '-o', '$TARGET', '$CXXDEPGEN', '-I$[CPPPATH]', '$CPPFLAGS', '$CXXFLAGS', '$SOURCES'],
      }
    end

    def produces?(target, source, env)
      target.has_suffix?(env['OBJSUFFIX']) and (
        source.has_suffix?(env['ASSUFFIX']) or
        source.has_suffix?(env['CSUFFIX']) or
        source.has_suffix?(env['CXXSUFFIX']))
    end

    def run(target, sources, cache, env, vars = {})
      vars = vars.merge({
        'TARGET' => target,
        'SOURCES' => sources,
        'DEPFILE' => target.set_suffix('.mf'),
      })
      com_prefix = if sources.first.has_suffix?(env['ASSUFFIX'])
                     'AS'
                   elsif sources.first.has_suffix?(env['CSUFFIX'])
                     'CC'
                   elsif sources.first.has_suffix?(env['CXXSUFFIX'])
                     'CXX'
                   else
                     raise "Error: unknown input file type: #{sources.first.inspect}"
                   end
      command = env.build_command(env["#{com_prefix}COM"], vars)
      unless cache.up_to_date?(target, command, sources)
        FileUtils.mkdir_p(File.dirname(target))
        FileUtils.rm_f(target)
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
