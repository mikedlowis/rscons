module Rscons
  describe VarSet do
    describe '.initialize' do
      it "initializes variables from a Hash" do
        v = VarSet.new({"one" => 1, "two" => :two})
        v["one"].should == 1
        v["two"].should == :two
      end
      it "initializes variables from another VarSet" do
        v = VarSet.new({"one" => 1})
        v2 = VarSet.new(v)
        v2["one"].should == 1
      end
      it "makes a deep copy of the given VarSet" do
        v = VarSet.new({"array" => [1, 2, 3]})
        v2 = VarSet.new(v)
        v["array"] << 4
        v["array"].should == [1, 2, 3, 4]
        v2["array"].should == [1, 2, 3]
      end
    end

    describe :[] do
      v = VarSet.new({"fuz" => "a string", "foo" => 42, "bar" => :baz,
                      "qax" => [3, 6], "qux" => {a: :b}})
      it "allows accessing a variable with its verbatim value if type is not specified" do
        v["fuz"].should == "a string"
        v["foo"].should == 42
        v["bar"].should == :baz
        v["qax"].should == [3, 6]
        v["qux"].should == {a: :b}
      end
    end

    describe :[]= do
      it "allows assigning to variables" do
        v = VarSet.new("CFLAGS" => ["-Wall", "-O3"])
        v["CPPPATH"] = ["one", "two"]
        v["CFLAGS"].should == ["-Wall", "-O3"]
        v["CPPPATH"].should == ["one", "two"]
      end
    end

    describe '.append' do
      it "adds values from a Hash to the VarSet" do
        v = VarSet.new("LDFLAGS" => "-lgcc")
        v.append("LIBS" => "gcc", "LIBPATH" => ["mylibs"])
        v.vars.keys.should =~ ["LDFLAGS", "LIBS", "LIBPATH"]
      end
      it "adds values from another VarSet to the VarSet" do
        v = VarSet.new("CPPPATH" => ["mydir"])
        v2 = VarSet.new("CFLAGS" => ["-O0"], "CPPPATH" => ["different_dir"])
        v.append(v2)
        v.vars.keys.should =~ ["CPPPATH", "CFLAGS"]
        v["CPPPATH"].should == ["different_dir"]
      end
    end

    describe '.merge' do
      it "returns a new VarSet merged with the given Hash" do
        v = VarSet.new("foo" => "yoda")
        v2 = v.merge("baz" => "qux")
        v.vars.keys.should == ["foo"]
        v2.vars.keys.should =~ ["foo", "baz"]
      end
      it "returns a new VarSet merged with the given VarSet" do
        v = VarSet.new("foo" => ["a", "b"], "bar" => 42)
        v2 = v.merge(VarSet.new("bar" => 33, "baz" => :baz))
        v2["foo"] << "c"
        v["foo"].should == ["a", "b"]
        v["bar"].should == 42
        v2["foo"].should == ["a", "b", "c"]
        v2["bar"].should == 33
      end
    end

    describe '.expand_varref' do
      v = VarSet.new("CFLAGS" => ["-Wall", "-O2"],
                     "CC" => "gcc",
                     "CPPPATH" => ["dir1", "dir2"],
                     "compiler" => "${CC}",
                     "cmd" => ["${CC}", "-c", "${CFLAGS}", "-I${CPPPATH}"])
      it "expands to the string itself if the string is not a variable reference" do
        v.expand_varref("CC").should == "CC"
        v.expand_varref("CPPPATH").should == "CPPPATH"
        v.expand_varref("str").should == "str"
      end
      it "expands a single variable reference beginning with a '$'" do
        v.expand_varref("${CC}").should == "gcc"
        v.expand_varref("${CPPPATH}").should == ["dir1", "dir2"]
      end
      it "expands a single variable reference in ${arr} notation" do
        v.expand_varref("prefix${CFLAGS}suffix").should == ["prefix-Wallsuffix", "prefix-O2suffix"]
        v.expand_varref(v["cmd"]).should == ["gcc", "-c", "-Wall", "-O2", "-Idir1", "-Idir2"]
      end
      it "expands a variable reference recursively" do
        v.expand_varref("${compiler}").should == "gcc"
        v.expand_varref("${cmd}").should == ["gcc", "-c", "-Wall", "-O2", "-Idir1", "-Idir2"]
      end
      it "resolves multiple variable references in one element by enumerating all combinations" do
        v.expand_varref("cflag: ${CFLAGS}, cpppath: ${CPPPATH}, compiler: ${compiler}").should == [
          "cflag: -Wall, cpppath: dir1, compiler: gcc",
          "cflag: -O2, cpppath: dir1, compiler: gcc",
          "cflag: -Wall, cpppath: dir2, compiler: gcc",
          "cflag: -O2, cpppath: dir2, compiler: gcc",
        ]
      end
      it "raises an error when a variable reference refers to a non-existent variable" do
        expect { v.expand_varref("${not_here}") }.to raise_error /I do not know how to expand a variable reference to a NilClass/
      end
    end
  end
end
