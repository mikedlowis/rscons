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
        'LIBPATHS' => [],
        'LIBS' => [],
        'LDCOM' => ['$LD', '-o', '$TARGET', '$LDFLAGS', '$SOURCES', '-L$[LIBPATHS]', '-l$[LIBS]']
      }
    end

    def run(target, sources, cache, env)
      # convert sources to object file names
      objects = sources.map do |source|
        if source.has_suffix?([env['OBJSUFFIX'], env['LIBSUFFIX']])
          source
        else
          o_file = env.get_build_fname(source, env['OBJSUFFIX', :string])
          builder = env.builders.values.find { |b| b.produces?(o_file, source, env) }
          builder or raise "No builder found to convert input source #{source.inspect} to an object file."
          builder.run(o_file, [source], cache, env) or break
        end
      end
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
