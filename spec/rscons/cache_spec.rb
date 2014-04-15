module Rscons
  describe Cache do
    before do
      File.stub(:read) { nil }
    end

    def build_from(cache)
      JSON.stub(:load) do
        cache
      end
      Cache.instance.tap do |cache|
        cache.send(:initialize!)
      end
    end

    describe "#initialize" do
      context "when corrupt" do
        it "prints a warning and defaults to an empty hash" do
          JSON.should_receive(:load).and_return("string")
          $stderr.should_receive(:puts).with(/Warning:.*was.corrupt/)
          c = Cache.instance
          c.send(:initialize!)
          c.instance_variable_get(:@cache).is_a?(Hash).should be_true
        end
      end
    end

    describe "#clear" do
      it "removes the cache file" do
        FileUtils.should_receive(:rm_f).with(Cache::CACHE_FILE)
        JSON.stub(:load) {{}}
        Cache.instance.clear
      end
    end

    describe "#write" do
      it "should fill in 'version' and write to file" do
        cache = {}
        fh = $stdout
        fh.should_receive(:puts)
        File.should_receive(:open).and_yield(fh)
        build_from(cache).write
        cache["version"].should == Rscons::VERSION
      end
    end

    describe "#up_to_date?" do
      empty_env = "env"
      before do
        empty_env.stub(:get_user_deps) { nil }
      end

      it "returns false when target file does not exist" do
        File.should_receive(:exists?).with("target").and_return(false)
        build_from({}).up_to_date?("target", "command", [], empty_env).should be_false
      end

      it "returns false when target is not registered in the cache" do
        File.should_receive(:exists?).with("target").and_return(true)
        build_from({}).up_to_date?("target", "command", [], empty_env).should be_false
      end

      it "returns false when the target's checksum does not match" do
        _cache = {"targets" => {"target" => {"checksum" => "abc"}}}
        cache = build_from(_cache)
        File.should_receive(:exists?).with("target").and_return(true)
        cache.should_receive(:calculate_checksum).with("target").and_return("def")
        cache.up_to_date?("target", "command", [], empty_env).should be_false
      end

      it "returns false when the build command has changed" do
        _cache = {"targets" => {"target" => {"checksum" => "abc", "command" => Digest::MD5.hexdigest("old command".inspect)}}}
        cache = build_from(_cache)
        File.should_receive(:exists?).with("target").and_return(true)
        cache.should_receive(:calculate_checksum).with("target").and_return("abc")
        cache.up_to_date?("target", "command", [], empty_env).should be_false
      end

      it "returns false when there is a new dependency" do
        _cache = {"targets" => {"target" => {"checksum" => "abc",
                                         "command" => Digest::MD5.hexdigest("command".inspect),
                                         "deps" => [{"fname" => "dep.1"}]}}}
        cache = build_from(_cache)
        File.should_receive(:exists?).with("target").and_return(true)
        cache.should_receive(:calculate_checksum).with("target").and_return("abc")
        cache.up_to_date?("target", "command", ["dep.1", "dep.2"], empty_env).should be_false
      end

      it "returns false when a dependency's checksum has changed" do
        _cache = {"targets" => {"target" => {"checksum" => "abc",
                                         "command" => Digest::MD5.hexdigest("command".inspect),
                                         "deps" => [{"fname" => "dep.1",
                                                 "checksum" => "dep.1.chk"},
                                                {"fname" => "dep.2",
                                                 "checksum" => "dep.2.chk"},
                                                {"fname" => "extra.dep",
                                                 "checksum" => "extra.dep.chk"}],
                                         "user_deps" => []}}}
        cache = build_from(_cache)
        File.should_receive(:exists?).with("target").and_return(true)
        cache.should_receive(:calculate_checksum).with("target").and_return("abc")
        cache.should_receive(:calculate_checksum).with("dep.1").and_return("dep.1.chk")
        cache.should_receive(:calculate_checksum).with("dep.2").and_return("dep.2.changed")
        cache.up_to_date?("target", "command", ["dep.1", "dep.2"], empty_env).should be_false
      end

      it "returns false with strict_deps=true when cache has an extra dependency" do
        _cache = {"targets" => {"target" => {"checksum" => "abc",
                                         "command" => Digest::MD5.hexdigest("command".inspect),
                                         "deps" => [{"fname" => "dep.1",
                                                 "checksum" => "dep.1.chk"},
                                                {"fname" => "dep.2",
                                                 "checksum" => "dep.2.chk"},
                                                {"fname" => "extra.dep",
                                                 "checksum" => "extra.dep.chk"}],
                                         "user_deps" => []}}}
        cache = build_from(_cache)
        File.should_receive(:exists?).with("target").and_return(true)
        cache.should_receive(:calculate_checksum).with("target").and_return("abc")
        cache.up_to_date?("target", "command", ["dep.1", "dep.2"], empty_env, strict_deps: true).should be_false
      end

      it "returns false when there is a new user dependency" do
        _cache = {"targets" => {"target" => {"checksum" => "abc",
                                         "command" => Digest::MD5.hexdigest("command".inspect),
                                         "deps" => [{"fname" => "dep.1"}],
                                         "user_deps" => []}}}
        cache = build_from(_cache)
        env = "env"
        env.should_receive(:get_user_deps).with("target").and_return(["file.ld"])
        File.should_receive(:exists?).with("target").and_return(true)
        cache.should_receive(:calculate_checksum).with("target").and_return("abc")
        cache.up_to_date?("target", "command", ["dep.1"], env).should be_false
      end

      it "returns false when a user dependency checksum has changed" do
        _cache = {"targets" => {"target" => {"checksum" => "abc",
                                         "command" => Digest::MD5.hexdigest("command".inspect),
                                         "deps" => [{"fname" => "dep.1",
                                                 "checksum" => "dep.1.chk"},
                                                {"fname" => "dep.2",
                                                 "checksum" => "dep.2.chk"},
                                                {"fname" => "extra.dep",
                                                 "checksum" => "extra.dep.chk"}],
                                         "user_deps" => [{"fname" => "user.dep",
                                                      "checksum" => "user.dep.chk"}]}}}
        cache = build_from(_cache)
        env = "env"
        env.should_receive(:get_user_deps).with("target").and_return(["user.dep"])
        File.should_receive(:exists?).with("target").and_return(true)
        cache.should_receive(:calculate_checksum).with("target").and_return("abc")
        cache.should_receive(:calculate_checksum).with("dep.1").and_return("dep.1.chk")
        cache.should_receive(:calculate_checksum).with("dep.2").and_return("dep.2.chk")
        cache.should_receive(:calculate_checksum).with("extra.dep").and_return("extra.dep.chk")
        cache.should_receive(:calculate_checksum).with("user.dep").and_return("INCORRECT")
        cache.up_to_date?("target", "command", ["dep.1", "dep.2"], env).should be_false
      end

      it "returns true when no condition for false is met" do
        _cache = {"targets" => {"target" => {"checksum" => "abc",
                                         "command" => Digest::MD5.hexdigest("command".inspect),
                                         "deps" => [{"fname" => "dep.1",
                                                 "checksum" => "dep.1.chk"},
                                                {"fname" => "dep.2",
                                                 "checksum" => "dep.2.chk"},
                                                {"fname" => "extra.dep",
                                                 "checksum" => "extra.dep.chk"}],
                                         "user_deps" => []}}}
        cache = build_from(_cache)
        File.should_receive(:exists?).with("target").and_return(true)
        cache.should_receive(:calculate_checksum).with("target").and_return("abc")
        cache.should_receive(:calculate_checksum).with("dep.1").and_return("dep.1.chk")
        cache.should_receive(:calculate_checksum).with("dep.2").and_return("dep.2.chk")
        cache.should_receive(:calculate_checksum).with("extra.dep").and_return("extra.dep.chk")
        cache.up_to_date?("target", "command", ["dep.1", "dep.2"], empty_env).should be_true
      end
    end

    describe "#register_build" do
      it "stores the given information in the cache" do
        _cache = {}
        cache = build_from(_cache)
        env = "env"
        env.should_receive(:get_user_deps).with("the target").and_return(["user.dep"])
        cache.should_receive(:calculate_checksum).with("the target").and_return("the checksum")
        cache.should_receive(:calculate_checksum).with("dep 1").and_return("dep 1 checksum")
        cache.should_receive(:calculate_checksum).with("dep 2").and_return("dep 2 checksum")
        cache.should_receive(:calculate_checksum).with("user.dep").and_return("user.dep checksum")
        cache.register_build("the target", "the command", ["dep 1", "dep 2"], env)
        cached_target = cache.instance_variable_get(:@cache)["targets"]["the target"]
        cached_target.should_not be_nil
        cached_target["command"].should == Digest::MD5.hexdigest("the command".inspect)
        cached_target["checksum"].should == "the checksum"
        cached_target["deps"].should == [
          {"fname" => "dep 1", "checksum" => "dep 1 checksum"},
          {"fname" => "dep 2", "checksum" => "dep 2 checksum"},
        ]
        cached_target["user_deps"].should == [
          {"fname" => "user.dep", "checksum" => "user.dep checksum"},
        ]
      end
    end

    describe "#targets" do
      it "returns a list of targets that are cached" do
        cache = {"targets" => {"t1" => {}, "t2" => {}, "t3" => {}}}
        build_from(cache).targets.should == ["t1", "t2", "t3"]
      end
    end

    describe "#mkdir_p" do
      it "makes directories and records any created in the cache" do
        _cache = {}
        cache = build_from(_cache)
        File.should_receive(:exists?).with("one").and_return(true)
        File.should_receive(:exists?).with("one/two").and_return(false)
        FileUtils.should_receive(:mkdir).with("one/two")
        File.should_receive(:exists?).with("one/two/three").and_return(false)
        FileUtils.should_receive(:mkdir).with("one/two/three")
        File.should_receive(:exists?).with("one").and_return(true)
        File.should_receive(:exists?).with("one/two").and_return(true)
        File.should_receive(:exists?).with("one/two/four").and_return(false)
        FileUtils.should_receive(:mkdir).with("one/two/four")
        cache.mkdir_p("one/two/three")
        cache.mkdir_p("one\\two\\four")
        cache.directories.should == ["one/two", "one/two/three", "one/two/four"]
      end

      it "handles absolute paths" do
        _cache = {}
        cache = build_from(_cache)
        File.should_receive(:exists?).with("/one").and_return(true)
        File.should_receive(:exists?).with("/one/two").and_return(false)
        FileUtils.should_receive(:mkdir).with("/one/two")
        cache.mkdir_p("/one/two")
        cache.directories.should == ["/one/two"]
      end
    end

    describe "#directories" do
      it "returns a list of directories that are cached" do
        _cache = {"directories" => {"dir1" => true, "dir2" => true}}
        build_from(_cache).directories.should == ["dir1", "dir2"]
      end
    end

    describe "#lookup_checksum" do
      it "does not re-calculate the checksum when it is already cached" do
        cache = build_from({})
        cache.instance_variable_set(:@lookup_checksums, {"f1" => "f1.chk"})
        cache.should_not_receive(:calculate_checksum)
        cache.send(:lookup_checksum, "f1").should == "f1.chk"
      end

      it "calls calculate_checksum when the checksum is not cached" do
        cache = build_from({})
        cache.should_receive(:calculate_checksum).with("f1").and_return("ck")
        cache.send(:lookup_checksum, "f1").should == "ck"
      end
    end

    describe "#calculate_checksum" do
      it "calculates the MD5 of the file contents" do
        contents = "contents"
        File.should_receive(:read).with("fname", mode: "rb").and_return(contents)
        Digest::MD5.should_receive(:hexdigest).with(contents).and_return("the_checksum")
        build_from({}).send(:calculate_checksum, "fname").should == "the_checksum"
      end
    end
  end
end
