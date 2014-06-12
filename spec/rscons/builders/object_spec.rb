module Rscons
  module Builders
    describe Object do
      let(:env) {Environment.new}
      subject {Object.new}

      it "supports overriding CCCMD construction variable" do
        cache = "cache"
        cache.stub(:up_to_date?) { false }
        cache.stub(:mkdir_p) { }
        cache.stub(:register_build) { }
        FileUtils.stub(:rm_f) { }
        File.stub(:exists?) { false }
        expect(env).to receive(:execute).with("CC mod.o", ["llc", "mod.c"]).and_return(true)
        subject.run("mod.o", ["mod.c"], cache, env, "CCCMD" => ["llc", "${_SOURCES}"])
      end

      it "raises an error when given a source file with an unknown suffix" do
        expect { subject.run("mod.o", ["mod.xyz"], :cache, env, {}) }.to raise_error /unknown input file type: "mod.xyz"/
      end
    end
  end
end
