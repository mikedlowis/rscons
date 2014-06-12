module Rscons
  module Builders
    describe Disassemble do
      let(:env) {Environment.new}
      subject {Disassemble.new}

      it "supports overriding DISASM_CMD construction variable" do
        cache = "cache"
        allow(cache).to receive(:up_to_date?) { false }
        allow(cache).to receive(:mkdir_p) { }
        allow(cache).to receive(:register_build) { }
        expect(env).to receive(:execute).with("Disassemble a_file.txt", ["my_disasm", "a_file.exe"], anything).and_return(true)
        subject.run("a_file.txt", ["a_file.exe"], cache, env, "DISASM_CMD" => ["my_disasm", "${_SOURCES}"])
      end
    end
  end
end
