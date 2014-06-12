module Rscons
  module Builders
    describe CFile do
      let(:env) {Environment.new}
      subject {CFile.new}

      it "invokes bison to create a .c file from a .y file" do
        expect(subject).to receive(:standard_build).with("YACC parser.c", "parser.c", ["bison", "-d", "-o", "parser.c", "parser.y"], ["parser.y"], env, :cache)
        subject.run("parser.c", ["parser.y"], :cache, env, {})
      end

      it "invokes a custom lexer to create a .cc file from a .ll file" do
        env["LEX"] = "custom_lex"
        expect(subject).to receive(:standard_build).with("LEX lexer.cc", "lexer.cc", ["custom_lex", "-o", "lexer.cc", "parser.ll"], ["parser.ll"], env, :cache)
        subject.run("lexer.cc", ["parser.ll"], :cache, env, {})
      end

      it "supports overriding construction variables" do
        expect(subject).to receive(:standard_build).with("LEX lexer.c", "lexer.c", ["hi", "parser.l"], ["parser.l"], env, :cache)
        subject.run("lexer.c", ["parser.l"], :cache, env, "LEX_CMD" => ["hi", "${_SOURCES}"])
      end

      it "raises an error when an unknown source file is specified" do
        expect {subject.run("file.c", ["foo.bar"], :cache, env, {})}.to raise_error /Unknown source file .foo.bar. for CFile builder/
      end
    end
  end
end
