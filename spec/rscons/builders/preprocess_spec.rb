module Rscons
  module Builders
    describe Preprocess do
      let(:env) {Environment.new}
      subject {Preprocess.new}

      it "supports overriding CC construction variable" do
        subject.should_receive(:standard_build).with("Preprocess module.pp", "module.pp", ["my_cpp", "-E", "-o", "module.pp", "module.c"], ["module.c"], env, :cache)
        subject.run("module.pp", ["module.c"], :cache, env, "CC" => "my_cpp")
      end

      it "supports overriding CPP_CMD construction variable" do
        subject.should_receive(:standard_build).with("Preprocess module.pp", "module.pp", ["my_cpp", "module.c"], ["module.c"], env, :cache)
        subject.run("module.pp", ["module.c"], :cache, env, "CPP_CMD" => ["my_cpp", "${_SOURCES}"])
      end
    end
  end
end
