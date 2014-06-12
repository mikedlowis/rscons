module Rscons
  module Builders
    describe Library do
      let(:env) {Environment.new}
      subject {Library.new}

      it "supports overriding AR construction variable" do
        expect(subject).to receive(:standard_build).with("AR prog.a", "prog.a", ["sp-ar", "rcs", "prog.a", "prog.o"], ["prog.o"], env, :cache)
        subject.run("prog.a", ["prog.o"], :cache, env, "AR" => "sp-ar")
      end

      it "supports overriding ARCMD construction variable" do
        expect(subject).to receive(:standard_build).with("AR prog.a", "prog.a", ["special", "AR!", "prog.o"], ["prog.o"], env, :cache)
        subject.run("prog.a", ["prog.o"], :cache, env, "ARCMD" => ["special", "AR!", "${_SOURCES}"])
      end
    end
  end
end
