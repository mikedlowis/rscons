module Rscons
  module Builders
    describe Program do
      let(:env) {Environment.new}
      subject {Program.new}

      it "supports overriding CC construction variable" do
        subject.should_receive(:standard_build).with("LD prog#{env["PROGSUFFIX"]}", "prog#{env["PROGSUFFIX"]}", ["sp-c++", "-o", "prog#{env["PROGSUFFIX"]}", "prog.o"], ["prog.o"], env, :cache)
        subject.run("prog", ["prog.o"], :cache, env, "CC" => "sp-c++")
      end

      it "supports overriding LDCMD construction variable" do
        subject.should_receive(:standard_build).with("LD prog.exe", "prog.exe", ["special", "LD!", "prog.o"], ["prog.o"], env, :cache)
        subject.run("prog", ["prog.o"], :cache, env, "LDCMD" => ["special", "LD!", "${_SOURCES}"])
      end
    end
  end
end
