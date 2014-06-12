describe Rscons do
  describe ".clean" do
    it "removes all build targets and created directories" do
      cache = "cache"
      Rscons::Cache.should_receive(:instance).and_return(cache)
      cache.should_receive(:targets).and_return(["build/a.out", "build/main.o"])
      FileUtils.should_receive(:rm_f).with("build/a.out")
      FileUtils.should_receive(:rm_f).with("build/main.o")
      cache.should_receive(:directories).and_return(["build/one", "build/one/two", "build", "other"])
      File.should_receive(:directory?).with("build/one/two").and_return(true)
      Dir.should_receive(:entries).with("build/one/two").and_return([".", ".."])
      Dir.should_receive(:rmdir).with("build/one/two")
      File.should_receive(:directory?).with("build/one").and_return(true)
      Dir.should_receive(:entries).with("build/one").and_return([".", ".."])
      Dir.should_receive(:rmdir).with("build/one")
      File.should_receive(:directory?).with("build").and_return(true)
      Dir.should_receive(:entries).with("build").and_return([".", ".."])
      Dir.should_receive(:rmdir).with("build")
      File.should_receive(:directory?).with("other").and_return(true)
      Dir.should_receive(:entries).with("other").and_return([".", "..", "other.file"])
      cache.should_receive(:clear)

      Rscons.clean
    end
  end

  describe ".get_system_shell" do
    before(:each) do
      Rscons.class_variable_set(:@@shell, nil)
    end

    after(:each) do
      Rscons.class_variable_set(:@@shell, nil)
    end

    it "uses the SHELL environment variable if it tests successfully" do
      my_ENV = {"SHELL" => "my_shell"}
      ENV.stub(:[]) {|*args| my_ENV[*args]}
      io = StringIO.new("success\n")
      IO.should_receive(:popen).with(["my_shell", "-c", "echo success"]).and_yield(io)
      expect(Rscons.get_system_shell).to eq(["my_shell", "-c"])
    end

    it "uses sh -c on a mingw platform if it tests successfully" do
      my_ENV = {"SHELL" => nil}
      ENV.stub(:[]) {|*args| my_ENV[*args]}
      io = StringIO.new("success\n")
      IO.should_receive(:popen).with(["sh", "-c", "echo success"]).and_yield(io)
      Object.should_receive(:const_get).with("RUBY_PLATFORM").and_return("x86-mingw")
      expect(Rscons.get_system_shell).to eq(["sh", "-c"])
    end

    it "uses cmd /c on a mingw platform if sh -c does not test successfully" do
      my_ENV = {"SHELL" => nil}
      ENV.stub(:[]) {|*args| my_ENV[*args]}
      io = StringIO.new("success\n")
      IO.should_receive(:popen).with(["sh", "-c", "echo success"]).and_raise "ENOENT"
      Object.should_receive(:const_get).with("RUBY_PLATFORM").and_return("x86-mingw")
      expect(Rscons.get_system_shell).to eq(["cmd", "/c"])
    end

    it "uses sh -c on a non-mingw platform if SHELL is not specified" do
      my_ENV = {"SHELL" => nil}
      ENV.stub(:[]) {|*args| my_ENV[*args]}
      Object.should_receive(:const_get).with("RUBY_PLATFORM").and_return("x86-linux")
      expect(Rscons.get_system_shell).to eq(["sh", "-c"])
    end
  end

  context "command executer" do
    describe ".command_executer" do
      before(:each) do
        Rscons.class_variable_set(:@@command_executer, nil)
      end

      after(:each) do
        Rscons.class_variable_set(:@@command_executer, nil)
      end

      it "returns ['env'] if mingw platform in MSYS and 'env' works" do
        Object.should_receive(:const_get).and_return("x86-mingw")
        ENV.should_receive(:keys).and_return(["MSYSCON"])
        io = StringIO.new("success\n")
        IO.should_receive(:popen).with(["env", "echo", "success"]).and_yield(io)
        expect(Rscons.command_executer).to eq(["env"])
      end

      it "returns [] if mingw platform in MSYS and 'env' does not work" do
        Object.should_receive(:const_get).and_return("x86-mingw")
        ENV.should_receive(:keys).and_return(["MSYSCON"])
        IO.should_receive(:popen).with(["env", "echo", "success"]).and_raise "ENOENT"
        expect(Rscons.command_executer).to eq([])
      end

      it "returns [] if mingw platform not in MSYS" do
        Object.should_receive(:const_get).and_return("x86-mingw")
        ENV.should_receive(:keys).and_return(["COMSPEC"])
        expect(Rscons.command_executer).to eq([])
      end

      it "returns [] if not mingw platform" do
        Object.should_receive(:const_get).and_return("x86-linux")
        expect(Rscons.command_executer).to eq([])
      end
    end

    describe ".command_executer=" do
      it "overrides the value of @@command_executer" do
        Rscons.class_variable_set(:@@command_executer, ["env"])
        Rscons.command_executer = []
        expect(Rscons.class_variable_get(:@@command_executer)).to eq([])
      end
    end
  end
end
