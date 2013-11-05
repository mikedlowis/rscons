module Rscons
  describe Environment do
    describe "#clone" do
      it 'should create unique copies of each construction variable' do
        env = Environment.new
        env["CPPPATH"] << "path1"
        env2 = env.clone
        env2["CPPPATH"] << "path2"
        env["CPPPATH"].should == ["path1"]
        env2["CPPPATH"].should == ["path1", "path2"]
      end
    end

    describe ".parse_makefile_deps" do
      it 'handles dependencies on one line' do
        File.should_receive(:read).with('makefile').and_return(<<EOS)
module.o: source.cc
EOS
        Environment.parse_makefile_deps('makefile', 'module.o').should == ['source.cc']
      end

      it 'handles dependencies split across many lines' do
        File.should_receive(:read).with('makefile').and_return(<<EOS)
module.o: module.c \\
  module.h \\
  other.h
EOS
        Environment.parse_makefile_deps('makefile', 'module.o').should == [
          'module.c', 'module.h', 'other.h']
      end
    end
  end
end
