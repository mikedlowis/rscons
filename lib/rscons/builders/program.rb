module Rscons
  class Program < Builder
    def default_variables
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
  end
end
