module Rscons
  describe Environment do
    describe "#initialize" do
      it "stores the construction variables passed in" do
        env = Environment.new("CFLAGS" => ["-g"], "CPPPATH" => ["dir"])
        env["CFLAGS"].should == ["-g"]
        env["CPPPATH"].should == ["dir"]
      end

      it "adds the default builders when they are not excluded" do
        env = Environment.new
        env.builders.size.should be > 0
        env.builders.map {|name, builder| builder.is_a?(Builder)}.all?.should be_true
        env.builders.find {|name, builder| name == "Object"}.should_not be_nil
        env.builders.find {|name, builder| name == "Program"}.should_not be_nil
        env.builders.find {|name, builder| name == "Library"}.should_not be_nil
      end

      it "excludes the default builders with exclude_builders: :all" do
        env = Environment.new(exclude_builders: :all)
        env.builders.size.should == 0
      end

      it "excludes the named builders" do
        env = Environment.new(exclude_builders: ["Library"])
        env.builders.size.should be > 0
        env.builders.find {|name, builder| name == "Object"}.should_not be_nil
        env.builders.find {|name, builder| name == "Program"}.should_not be_nil
        env.builders.find {|name, builder| name == "Library"}.should be_nil
      end
    end

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

    describe "#add_builder" do
      it "adds the builder to the list of builders" do
        env = Environment.new(exclude_builders: :all)
        env.builders.keys.should == []
        env.add_builder(Rscons::Object.new)
        env.builders.keys.should == ["Object"]
      end
    end

    describe "#get_build_fname" do
      context "with no build directories" do
        it "returns the name of the source file with suffix changed" do
          env = Environment.new
          env.get_build_fname("src/dir/file.c", ".o").should == "src/dir/file.o"
          env.get_build_fname("src\\dir\\other.d", ".a").should == "src/dir/other.a"
          env.get_build_fname("source.cc", ".o").should == "source.o"
        end
      end

      context "with build directories" do
        it "uses the build directories to create the output file name" do
          env = Environment.new
          env.build_dir("src", "bld")
          env.build_dir(%r{^libs/([^/]+)}, 'build/libs/\1')
          env.get_build_fname("src/input.cc", ".o").should == "bld/input.o"
          env.get_build_fname("libs/lib1/some/file.c", ".o").should == "build/libs/lib1/some/file.o"
          env.get_build_fname("libs/otherlib/otherlib.cc", ".o").should == "build/libs/otherlib/otherlib.o"
          env.get_build_fname("other_directory/o.d", ".a").should == "other_directory/o.a"
        end
      end
    end

    describe "#[]" do
      it "allows reading construction variables" do
        env = Environment.new("CFLAGS" => ["-g", "-Wall"])
        env["CFLAGS"].should == ["-g", "-Wall"]
      end
    end

    describe "#[]=" do
      it "allows writing construction variables" do
        env = Environment.new("CFLAGS" => ["-g", "-Wall"])
        env["CFLAGS"] -= ["-g"]
        env["CFLAGS"] += ["-O3"]
        env["CFLAGS"].should == ["-Wall", "-O3"]
        env["other_var"] = "val33"
        env["other_var"].should == "val33"
      end
    end

    describe "#append" do
      it "allows adding many construction variables at once" do
        env = Environment.new("CFLAGS" => ["-g"], "CPPPATH" => ["inc"])
        env.append("CFLAGS" => ["-Wall"], "CPPPATH" => ["include"])
        env["CFLAGS"].should == ["-Wall"]
        env["CPPPATH"].should == ["include"]
      end
    end

    describe "#process" do
      it "runs builders for all of the targets specified" do
        env = Environment.new
        env.Program("a.out", "main.c")

        cache = "cache"
        Cache.should_receive(:new).and_return(cache)
        env.should_receive(:run_builder).with(anything, "a.out", ["main.c"], cache, {}).and_return(true)
        cache.should_receive(:write)

        env.process
      end

      it "builds dependent targets first" do
        env = Environment.new
        env.Program("a.out", "main.o")
        env.Object("main.o", "other.cc")

        cache = "cache"
        Cache.should_receive(:new).and_return(cache)
        env.should_receive(:run_builder).with(anything, "main.o", ["other.cc"], cache, {}).and_return("main.o")
        env.should_receive(:run_builder).with(anything, "a.out", ["main.o"], cache, {}).and_return("a.out")
        cache.should_receive(:write)

        env.process
      end

      it "raises a BuildError when building fails" do
        env = Environment.new
        env.Program("a.out", "main.o")
        env.Object("main.o", "other.cc")

        cache = "cache"
        Cache.should_receive(:new).and_return(cache)
        env.should_receive(:run_builder).with(anything, "main.o", ["other.cc"], cache, {}).and_return(false)
        cache.should_receive(:write)

        expect { env.process }.to raise_error BuildError, /Failed.to.build.main.o/
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
