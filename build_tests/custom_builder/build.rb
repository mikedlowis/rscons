class MySource < Rscons::Builder
  def run(target, sources, cache, env, vars = {})
    File.open(target, 'w') do |fh|
      fh.puts <<EOF
#define THE_VALUE 5678
EOF
    end
    target
  end
end

Rscons::Environment.new(echo: :short, builders: [MySource.new]) do |env|
  env.MySource('inc.h', [])
  env.Program('program', Dir['*.c'])
end
