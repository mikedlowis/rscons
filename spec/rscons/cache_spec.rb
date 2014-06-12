module Rscons
  describe Cache do
    before do
      allow(File).to receive(:read) { nil }
    end

    def build_from(cache)
      allow(JSON).to receive(:load) do
        cache
      end
      Cache.instance.tap do |cache|
        cache.send(:initialize!)
      end
    end

    describe "#initialize" do
      context "when corrupt" do
        it "prints a warning and defaults to an empty hash" do
          expect(JSON).to receive(:load).and_return("string")
          expect($stderr).to receive(:puts).with(/Warning:.*was.corrupt/)
          c = Cache.instance
          c.send(:initialize!)
          expect(c.instance_variable_get(:@cache).is_a?(Hash)).to be_truthy
        end
      end
    end

    describe "#clear" do
      it "removes the cache file" do
        expect(FileUtils).to receive(:rm_f).with(Cache::CACHE_FILE)
        allow(JSON).to receive(:load) {{}}
        Cache.instance.clear
      end
    end

    describe "#write" do
      it "fills in 'version' and write to file" do
        cache = {}
        fh = $stdout
        expect(fh).to receive(:puts)
        expect(File).to receive(:open).and_yield(fh)
        build_from(cache).write
        expect(cache["version"]).to eq Rscons::VERSION
      end
    end

    describe "#up_to_date?" do
      empty_env = "env"
      before do
        allow(empty_env).to receive(:get_user_deps) { nil }
      end

      it "returns false when target file does not exist" do
        expect(File).to receive(:exists?).with("target").and_return(false)
        expect(build_from({}).up_to_date?("target", "command", [], empty_env)).to be_falsey
      end

      it "returns false when target is not registered in the cache" do
        expect(File).to receive(:exists?).with("target").and_return(true)
        expect(build_from({}).up_to_date?("target", "command", [], empty_env)).to be_falsey
      end

      it "returns false when the target's checksum does not match" do
        _cache = {"targets" => {"target" => {"checksum" => "abc"}}}
        cache = build_from(_cache)
        expect(File).to receive(:exists?).with("target").and_return(true)
        expect(cache).to receive(:calculate_checksum).with("target").and_return("def")
        expect(cache.up_to_date?("target", "command", [], empty_env)).to be_falsey
      end

      it "returns false when the build command has changed" do
        _cache = {"targets" => {"target" => {"checksum" => "abc", "command" => Digest::MD5.hexdigest("old command".inspect)}}}
        cache = build_from(_cache)
        expect(File).to receive(:exists?).with("target").and_return(true)
        expect(cache).to receive(:calculate_checksum).with("target").and_return("abc")
        expect(cache.up_to_date?("target", "command", [], empty_env)).to be_falsey
      end

      it "returns false when there is a new dependency" do
        _cache = {"targets" => {"target" => {"checksum" => "abc",
                                         "command" => Digest::MD5.hexdigest("command".inspect),
                                         "deps" => [{"fname" => "dep.1"}]}}}
        cache = build_from(_cache)
        expect(File).to receive(:exists?).with("target").and_return(true)
        expect(cache).to receive(:calculate_checksum).with("target").and_return("abc")
        expect(cache.up_to_date?("target", "command", ["dep.1", "dep.2"], empty_env)).to be_falsey
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
        expect(File).to receive(:exists?).with("target").and_return(true)
        expect(cache).to receive(:calculate_checksum).with("target").and_return("abc")
        expect(cache).to receive(:calculate_checksum).with("dep.1").and_return("dep.1.chk")
        expect(cache).to receive(:calculate_checksum).with("dep.2").and_return("dep.2.changed")
        expect(cache.up_to_date?("target", "command", ["dep.1", "dep.2"], empty_env)).to be_falsey
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
        expect(File).to receive(:exists?).with("target").and_return(true)
        expect(cache).to receive(:calculate_checksum).with("target").and_return("abc")
        expect(cache.up_to_date?("target", "command", ["dep.1", "dep.2"], empty_env, strict_deps: true)).to be_falsey
      end

      it "returns false when there is a new user dependency" do
        _cache = {"targets" => {"target" => {"checksum" => "abc",
                                         "command" => Digest::MD5.hexdigest("command".inspect),
                                         "deps" => [{"fname" => "dep.1"}],
                                         "user_deps" => []}}}
        cache = build_from(_cache)
        env = "env"
        expect(env).to receive(:get_user_deps).with("target").and_return(["file.ld"])
        expect(File).to receive(:exists?).with("target").and_return(true)
        expect(cache).to receive(:calculate_checksum).with("target").and_return("abc")
        expect(cache.up_to_date?("target", "command", ["dep.1"], env)).to be_falsey
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
        expect(env).to receive(:get_user_deps).with("target").and_return(["user.dep"])
        expect(File).to receive(:exists?).with("target").and_return(true)
        expect(cache).to receive(:calculate_checksum).with("target").and_return("abc")
        expect(cache).to receive(:calculate_checksum).with("dep.1").and_return("dep.1.chk")
        expect(cache).to receive(:calculate_checksum).with("dep.2").and_return("dep.2.chk")
        expect(cache).to receive(:calculate_checksum).with("extra.dep").and_return("extra.dep.chk")
        expect(cache).to receive(:calculate_checksum).with("user.dep").and_return("INCORRECT")
        expect(cache.up_to_date?("target", "command", ["dep.1", "dep.2"], env)).to be_falsey
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
        expect(File).to receive(:exists?).with("target").and_return(true)
        expect(cache).to receive(:calculate_checksum).with("target").and_return("abc")
        expect(cache).to receive(:calculate_checksum).with("dep.1").and_return("dep.1.chk")
        expect(cache).to receive(:calculate_checksum).with("dep.2").and_return("dep.2.chk")
        expect(cache).to receive(:calculate_checksum).with("extra.dep").and_return("extra.dep.chk")
        expect(cache.up_to_date?("target", "command", ["dep.1", "dep.2"], empty_env)).to be_truthy
      end
    end

    describe "#register_build" do
      it "stores the given information in the cache" do
        _cache = {}
        cache = build_from(_cache)
        env = "env"
        expect(env).to receive(:get_user_deps).with("the target").and_return(["user.dep"])
        expect(cache).to receive(:calculate_checksum).with("the target").and_return("the checksum")
        expect(cache).to receive(:calculate_checksum).with("dep 1").and_return("dep 1 checksum")
        expect(cache).to receive(:calculate_checksum).with("dep 2").and_return("dep 2 checksum")
        expect(cache).to receive(:calculate_checksum).with("user.dep").and_return("user.dep checksum")
        cache.register_build("the target", "the command", ["dep 1", "dep 2"], env)
        cached_target = cache.instance_variable_get(:@cache)["targets"]["the target"]
        expect(cached_target).to_not be_nil
        expect(cached_target["command"]).to eq Digest::MD5.hexdigest("the command".inspect)
        expect(cached_target["checksum"]).to eq "the checksum"
        expect(cached_target["deps"]).to eq [
          {"fname" => "dep 1", "checksum" => "dep 1 checksum"},
          {"fname" => "dep 2", "checksum" => "dep 2 checksum"},
        ]
        expect(cached_target["user_deps"]).to eq [
          {"fname" => "user.dep", "checksum" => "user.dep checksum"},
        ]
      end
    end

    describe "#targets" do
      it "returns a list of targets that are cached" do
        cache = {"targets" => {"t1" => {}, "t2" => {}, "t3" => {}}}
        expect(build_from(cache).targets).to eq ["t1", "t2", "t3"]
      end
    end

    describe "#mkdir_p" do
      it "makes directories and records any created in the cache" do
        _cache = {}
        cache = build_from(_cache)
        expect(File).to receive(:exists?).with("one").and_return(true)
        expect(File).to receive(:exists?).with("one/two").and_return(false)
        expect(FileUtils).to receive(:mkdir).with("one/two")
        expect(File).to receive(:exists?).with("one/two/three").and_return(false)
        expect(FileUtils).to receive(:mkdir).with("one/two/three")
        expect(File).to receive(:exists?).with("one").and_return(true)
        expect(File).to receive(:exists?).with("one/two").and_return(true)
        expect(File).to receive(:exists?).with("one/two/four").and_return(false)
        expect(FileUtils).to receive(:mkdir).with("one/two/four")
        cache.mkdir_p("one/two/three")
        cache.mkdir_p("one\\two\\four")
        expect(cache.directories).to eq ["one/two", "one/two/three", "one/two/four"]
      end

      it "handles absolute paths" do
        _cache = {}
        cache = build_from(_cache)
        expect(File).to receive(:exists?).with("/one").and_return(true)
        expect(File).to receive(:exists?).with("/one/two").and_return(false)
        expect(FileUtils).to receive(:mkdir).with("/one/two")
        cache.mkdir_p("/one/two")
        expect(cache.directories).to eq ["/one/two"]
      end
    end

    describe "#directories" do
      it "returns a list of directories that are cached" do
        _cache = {"directories" => {"dir1" => true, "dir2" => true}}
        expect(build_from(_cache).directories).to eq ["dir1", "dir2"]
      end
    end

    describe "#lookup_checksum" do
      it "does not re-calculate the checksum when it is already cached" do
        cache = build_from({})
        cache.instance_variable_set(:@lookup_checksums, {"f1" => "f1.chk"})
        expect(cache).to_not receive(:calculate_checksum)
        expect(cache.send(:lookup_checksum, "f1")).to eq "f1.chk"
      end

      it "calls calculate_checksum when the checksum is not cached" do
        cache = build_from({})
        expect(cache).to receive(:calculate_checksum).with("f1").and_return("ck")
        expect(cache.send(:lookup_checksum, "f1")).to eq "ck"
      end
    end

    describe "#calculate_checksum" do
      it "calculates the MD5 of the file contents" do
        contents = "contents"
        expect(File).to receive(:read).with("fname", mode: "rb").and_return(contents)
        expect(Digest::MD5).to receive(:hexdigest).with(contents).and_return("the_checksum")
        expect(build_from({}).send(:calculate_checksum, "fname")).to eq "the_checksum"
      end
    end
  end
end
