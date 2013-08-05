module Rscons
  describe Environment do
    describe '.parse_makefile_deps' do
      it 'handles dependencies on one line' do
        File.should_receive(:read).with('makefile').and_return(<<EOS)
module.o: source.cc
EOS
        env = Environment.new
        env.parse_makefile_deps('makefile', 'module.o').should == ['source.cc']
      end

      it 'handles dependencies split across many lines' do
        File.should_receive(:read).with('makefile').and_return(<<EOS)
module.o: module.c \\
  module.h \\
  other.h
EOS
        env = Environment.new
        env.parse_makefile_deps('makefile', 'module.o').should == [
          'module.c', 'module.h', 'other.h']
      end
    end
  end
end
