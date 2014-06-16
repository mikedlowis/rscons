module Rscons
  module Builders
    # The Preprocess builder invokes the C preprocessor
    class Preprocess < Builder
      # Return default construction variables for the builder.
      #
      # @param env [Environment] The Environment using the builder.
      #
      # @return [Hash] Default construction variables for the builder.
      def default_variables(env)
        {
          "CPP_CMD" => ["${_PREPROCESS_CC}", "-E", "-o", "${_TARGET}", "-I${CPPPATH}", "${CPPFLAGS}", "${CFLAGS}", "${_SOURCES}"],
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
        pp_cc = if sources.find {|s| s.end_with?(*env.expand_varref("${CXXSUFFIX}", vars))}
                  "${CXX}"
                else
                  "${CC}"
                end
        vars = vars.merge("_PREPROCESS_CC" => pp_cc,
                          "_TARGET" => target,
                          "_SOURCES" => sources)
        command = env.build_command("${CPP_CMD}", vars)
        standard_build("Preprocess #{target}", target, command, sources, env, cache)
      end
    end
  end
end
