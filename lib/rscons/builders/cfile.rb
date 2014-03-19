module Rscons
  module Builders
    # Build a C or C++ source file given a lex (.l, .ll) or yacc (.y, .yy)
    # input file.
    #
    # Examples::
    #   env.CFile("parser.tab.cc", "parser.yy")
    #   env.CFile("lex.yy.cc", "parser.ll")
    class CFile < Builder
      def default_variables(env)
        {
          "YACC" => "bison",
          "YACC_FLAGS" => ["-d"],
          "YACC_CMD" => ["${YACC}", "${YACC_FLAGS}", "-o", "${_TARGET}", "${_SOURCES}"],
          "LEX" => "flex",
          "LEX_FLAGS" => [],
          "LEX_CMD" => ["${LEX}", "${LEX_FLAGS}", "-o", "${_TARGET}", "${_SOURCES}"],
        }
      end

      def run(target, sources, cache, env, vars)
        vars = vars.merge({
          "_TARGET" => target,
          "_SOURCES" => sources,
        })
        cmd =
          case
          when sources.first.end_with?(".l", ".ll")
            "LEX"
          when sources.first.end_with?(".y", ".yy")
            "YACC"
          else
            raise "Unknown source file #{sources.first.inspect} for CFile builder"
          end
        command = env.build_command(env["#{cmd}_CMD"], vars)
        standard_build("#{cmd} #{target}", target, command, sources, env, cache)
      end
    end
  end
end
