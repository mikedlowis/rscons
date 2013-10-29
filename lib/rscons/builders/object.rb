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
        'ASDEPGEN' => ['-MMD', '-MF', '$_DEPFILE'],
        'ASCOM' => ['$AS', '-c', '-o', '$_TARGET', '$ASDEPGEN', '-I$[ASPPPATH]', '$ASPPFLAGS', '$ASFLAGS', '$_SOURCES'],

        'CPPFLAGS' => [],
        'CPPPATH' => [],

        'CC' => 'gcc',
        'CFLAGS' => [],
        'CSUFFIX' => '.c',
        'CCDEPGEN' => ['-MMD', '-MF', '$_DEPFILE'],
        'CCCOM' => ['$CC', '-c', '-o', '$_TARGET', '$CCDEPGEN', '-I$[CPPPATH]', '$CPPFLAGS', '$CFLAGS', '$_SOURCES'],

        'CXX' => 'g++',
        'CXXFLAGS' => [],
        'CXXSUFFIX' => '.cc',
        'CXXDEPGEN' => ['-MMD', '-MF', '$_DEPFILE'],
        'CXXCOM' =>['$CXX', '-c', '-o', '$_TARGET', '$CXXDEPGEN', '-I$[CPPPATH]', '$CPPFLAGS', '$CXXFLAGS', '$_SOURCES'],

        'DC' => 'gdc',
        'DFLAGS' => [],
        'DSUFFIX' => '.d',
        'D_IMPORT_PATH' => [],
        'DCCOM' => ['$DC', '-c', '-o', '$_TARGET', '-I$[D_IMPORT_PATH]', '$DFLAGS', '$_SOURCES'],
      }
    end

    def produces?(target, source, env)
      target.has_suffix?(env['OBJSUFFIX']) and (
        source.has_suffix?(env['ASSUFFIX']) or
        source.has_suffix?(env['CSUFFIX']) or
        source.has_suffix?(env['CXXSUFFIX']) or
        source.has_suffix?(env['DSUFFIX']))
    end

    def run(target, sources, cache, env, vars = {})
      vars = vars.merge({
        '_TARGET' => target,
        '_SOURCES' => sources,
        '_DEPFILE' => target.set_suffix('.mf'),
      })
      com_prefix = if sources.first.has_suffix?(env['ASSUFFIX'])
                     'AS'
                   elsif sources.first.has_suffix?(env['CSUFFIX'])
                     'CC'
                   elsif sources.first.has_suffix?(env['CXXSUFFIX'])
                     'CXX'
                   elsif sources.first.has_suffix?(env['DSUFFIX'])
                     'DC'
                   else
                     raise "Error: unknown input file type: #{sources.first.inspect}"
                   end
      command = env.build_command(env["#{com_prefix}COM"], vars)
      unless cache.up_to_date?(target, command, sources)
        cache.mkdir_p(File.dirname(target))
        FileUtils.rm_f(target)
        return false unless env.execute("#{com_prefix} #{target}", command)
        deps = sources
        if File.exists?(vars['_DEPFILE'])
          deps += env.parse_makefile_deps(vars['_DEPFILE'], target)
          FileUtils.rm_f(vars['_DEPFILE'])
        end
        cache.register_build(target, command, deps.uniq)
      end
      target
    end
  end
end
