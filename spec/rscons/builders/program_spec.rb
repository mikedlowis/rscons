module Rscons
  module Builders
    describe Program do
      let(:env) {Environment.new}
      subject {Program.new}

      it "supports overriding CC construction variable" do
        expect(subject).to receive(:standard_build).with("LD prog", "prog", ["sp-c++", "-o", "prog", "prog.o"], ["prog.o"], env, :cache)
        subject.run("prog", ["prog.o"], :cache, env, "CC" => "sp-c++")
      end

      it "supports overriding LDCMD construction variable" do
        expect(subject).to receive(:standard_build).with("LD prog.exe", "prog.exe", ["special", "LD!", "prog.o"], ["prog.o"], env, :cache)
        subject.run("prog.exe", ["prog.o"], :cache, env, "LDCMD" => ["special", "LD!", "${_SOURCES}"])
      end
    end
  end
end
