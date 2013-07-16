module Rscons
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
      sources = sources.map do |source|
        if source.has_suffix?([env['OBJSUFFIX'], env['LIBSUFFIX']])
          source
        else
          o_file = env.get_build_fname(source, env['OBJSUFFIX', :string])
          builder = env.builders.values.find { |b| b.produces?(o_file, source, env) }
          builder or raise "No builder found to convert input source #{source.inspect} to an object file."
          builder.run(o_file, [source], cache, env) or break
        end
      end
      if sources
        vars = {
          'TARGET' => target,
          'SOURCES' => sources,
          'LD' => env['LD'] || env['CC'], # TODO: figure out whether to use CC or CXX
        }
        command = env.build_command(env['LDCOM'], vars)
        unless cache.up_to_date?(target, command, sources)
          return false unless env.execute("LD #{target}", command)
          cache.register_build(target, command, sources)
        end
        target
      end
    end
  end
end
