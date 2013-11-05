describe Rscons do
  describe ".clean" do
    it "removes all build targets and created directories" do
      cache = "cache"
      Rscons::Cache.should_receive(:new).and_return(cache)
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
      Rscons::Cache.should_receive(:clear)

      Rscons.clean
    end
  end
end
