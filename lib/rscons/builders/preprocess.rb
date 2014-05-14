module Rscons
  module Builders
    # The Preprocess builder invokes the C preprocessor
    class Preprocess < Builder
      def default_variables(env)
        {
          "CPP_CMD" => ["${_PREPROCESS_CC}", "-E", "-o", "${_TARGET}", "-I${CPPPATH}", "${CPPFLAGS}", "${CFLAGS}", "${_SOURCES}"],
        }
      end

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
