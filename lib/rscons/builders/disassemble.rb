module Rscons
  module Builders
    # The Disassemble builder produces a disassembly listing of a source file.
    class Disassemble < Builder
      # Return default construction variables for the builder.
      #
      # @param env [Environment] The Environment using the builder.
      #
      # @return [Hash] Default construction variables for the builder.
      def default_variables(env)
        {
          "OBJDUMP" => "objdump",
          "DISASM_CMD" => ["${OBJDUMP}", "${DISASM_FLAGS}", "${_SOURCES}"],
          "DISASM_FLAGS" => ["--disassemble", "--source"],
        }
      end

      # Run the builder to produce a build target.
      #
      # @param target [String] Target file name.
      # @param sources [Array<String>] Source file name(s).
      # @param cache [Cache] The Cache object.
      # @param env [Environment] The Environment executing the builder.
      # @param vars [Hash,VarSet] Extra construction variables.
      #
      # @return [String,false]
      #   Name of the target file on success or false on failure.
      def run(target, sources, cache, env, vars)
        vars = vars.merge("_SOURCES" => sources)
        command = env.build_command("${DISASM_CMD}", vars)
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
