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

    def run(target, sources, cache)
      # convert sources to object file names
      sources = sources.map do |source|
        if source.has_suffix?([@env['OBJSUFFIX'], @env['LIBSUFFIX']])
          source
        else
          o_file = source.set_suffix(@env['OBJSUFFIX', :string])
          builder = @env.builders.values.find { |b| b.produces?(o_file, source) }
          builder or raise "No builder found to convert input source #{source.inspect} to an object file."
          builder.run(o_file, [source], cache)
        end
      end
      unless cache.up_to_date?(target, sources)
        vars = {
          'TARGET' => target,
          'SOURCES' => sources,
          'LD' => @env['LD'] || @env['CC'], # TODO: figure out whether to use CC or CXX
        }
        @env.execute("LD #{target}", @env['LDCOM'], vars)
      end
      target
    end
  end
end
