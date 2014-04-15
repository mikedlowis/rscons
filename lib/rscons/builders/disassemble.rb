module Rscons
  module Builders
    # The Disassemble builder produces a disassembly listing of a source file.
    class Disassemble < Builder
      def default_variables(env)
        {
          "OBJDUMP" => "objdump",
          "DISASM_CMD" => ["${OBJDUMP}", "${DISASM_FLAGS}", "${_SOURCES}"],
          "DISASM_FLAGS" => ["--disassemble", "--source"],
        }
      end

      def run(target, sources, cache, env, vars)
        vars = vars.merge("_SOURCES" => sources)
        command = env.build_command(env["DISASM_CMD"], vars)
        unless cache.up_to_date?(target, command, sources, env)
          cache.mkdir_p(File.dirname(target))
          return false unless env.execute("Disassemble #{target}", command, options: {out: target})
          cache.register_build(target, command, sources, env)
        end
        target
      end
    end
  end
end
