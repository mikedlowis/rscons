module Rscons
  describe VarSet do
    describe '#initialize' do
      it "initializes variables from a Hash" do
        v = VarSet.new({"one" => 1, "two" => :two})
        expect(v["one"]).to eq(1)
        expect(v["two"]).to eq(:two)
      end
      it "initializes variables from another VarSet" do
        v = VarSet.new({"one" => 1})
        v2 = VarSet.new(v)
        expect(v2["one"]).to eq 1
      end
      it "makes a deep copy of the given VarSet" do
        v = VarSet.new({"array" => [1, 2, 3]})
        v2 = VarSet.new(v)
        v["array"] << 4
        expect(v["array"]).to eq([1, 2, 3, 4])
        expect(v2["array"]).to eq([1, 2, 3])
      end
    end

    describe "#[]" do
      it "allows accessing a variable with its verbatim value if type is not specified" do
        v = VarSet.new({"fuz" => "a string", "foo" => 42, "bar" => :baz,
                        "qax" => [3, 6], "qux" => {a: :b}})
        expect(v["fuz"]).to eq("a string")
        expect(v["foo"]).to eq(42)
        expect(v["bar"]).to eq(:baz)
        expect(v["qax"]).to eq([3, 6])
        expect(v["qux"]).to eq({a: :b})
      end
    end

    describe "#[]=" do
      it "allows assigning to variables" do
        v = VarSet.new("CFLAGS" => ["-Wall", "-O3"])
        v["CPPPATH"] = ["one", "two"]
        expect(v["CFLAGS"]).to eq(["-Wall", "-O3"])
        expect(v["CPPPATH"]).to eq(["one", "two"])
      end
    end

    describe "#include?" do
      it "returns whether the variable is in the VarSet" do
        v = VarSet.new("CFLAGS" => [], :foo => :bar)

        expect(v.include?("CFLAGS")).to be_true
        expect(v.include?(:CFLAGS)).to be_false
        expect(v.include?(:foo)).to be_true
        expect(v.include?("foo")).to be_false
        expect(v.include?("bar")).to be_false

        v2 = v.clone
        v2.append("bar" => [])

        expect(v2.include?("CFLAGS")).to be_true
        expect(v2.include?(:CFLAGS)).to be_false
        expect(v2.include?(:foo)).to be_true
        expect(v2.include?("foo")).to be_false
        expect(v2.include?("bar")).to be_true
      end
    end

    describe '#append' do
      it "adds values from a Hash to the VarSet" do
        v = VarSet.new("LDFLAGS" => "-lgcc")
        v.append("LIBS" => "gcc", "LIBPATH" => ["mylibs"])
        expect(v["LDFLAGS"]).to eq("-lgcc")
        expect(v["LIBS"]).to eq("gcc")
        expect(v["LIBPATH"]).to eq(["mylibs"])
      end

      it "adds values from another VarSet to the VarSet" do
        v = VarSet.new("CPPPATH" => ["mydir"])
        v2 = VarSet.new("CFLAGS" => ["-O0"], "CPPPATH" => ["different_dir"])
        v.append(v2)
        expect(v["CFLAGS"]).to eq(["-O0"])
        expect(v["CPPPATH"]).to eq(["different_dir"])
      end

      it "does not pick up subsequent variable changes from a given VarSet" do
        v = VarSet.new("dirs" => ["a"])
        v2 = VarSet.new
        v2.append(v)
        v["dirs"] << "b"
        expect(v["dirs"]).to eq(["a", "b"])
        expect(v2["dirs"]).to eq(["a"])
      end
    end

    describe '#merge' do
      it "returns a new VarSet merged with the given Hash" do
        v = VarSet.new("foo" => "yoda")
        v2 = v.merge("baz" => "qux")
        expect(v["foo"]).to eq("yoda")
        expect(v2["foo"]).to eq("yoda")
        expect(v2["baz"]).to eq("qux")
      end

      it "returns a new VarSet merged with the given VarSet" do
        v = VarSet.new("foo" => ["a", "b"], "bar" => 42)
        v2 = v.merge(VarSet.new("bar" => 33, "baz" => :baz))
        v2["foo"] << "c"
        expect(v["foo"]).to eq ["a", "b"]
        expect(v["bar"]).to eq 42
        expect(v2["foo"]).to eq ["a", "b", "c"]
        expect(v2["bar"]).to eq 33
      end

      it "does not pick up subsequent variable changes from a given VarSet" do
        v = VarSet.new("var" => ["a", "b"], "var2" => ["1", "2"])
        v["var2"] << "3"
        v2 = v.clone
        v["var"] << "c"
        expect(v["var"]).to eq(["a", "b", "c"])
        expect(v["var2"]).to eq(["1", "2", "3"])
        expect(v2["var"]).to eq(["a", "b"])
        expect(v2["var2"]).to eq(["1", "2", "3"])
      end
    end

    describe '#expand_varref' do
      v = VarSet.new("CFLAGS" => ["-Wall", "-O2"],
                     "CC" => "gcc",
                     "CPPPATH" => ["dir1", "dir2"],
                     "compiler" => "${CC}",
                     "cmd" => ["${CC}", "-c", "${CFLAGS}", "-I${CPPPATH}"],
                     "hash" => {})
      it "expands to the string itself if the string is not a variable reference" do
        expect(v.expand_varref("CC")).to eq("CC")
        expect(v.expand_varref("CPPPATH")).to eq("CPPPATH")
        expect(v.expand_varref("str")).to eq("str")
      end
      it "expands a single variable reference beginning with a '$'" do
        expect(v.expand_varref("${CC}")).to eq("gcc")
        expect(v.expand_varref("${CPPPATH}")).to eq(["dir1", "dir2"])
      end
      it "expands a single variable reference in ${arr} notation" do
        expect(v.expand_varref("prefix${CFLAGS}suffix")).to eq(["prefix-Wallsuffix", "prefix-O2suffix"])
        expect(v.expand_varref(v["cmd"])).to eq(["gcc", "-c", "-Wall", "-O2", "-Idir1", "-Idir2"])
      end
      it "expands a variable reference recursively" do
        expect(v.expand_varref("${compiler}")).to eq("gcc")
        expect(v.expand_varref("${cmd}")).to eq(["gcc", "-c", "-Wall", "-O2", "-Idir1", "-Idir2"])
      end
      it "resolves multiple variable references in one element by enumerating all combinations" do
        expect(v.expand_varref("cflag: ${CFLAGS}, cpppath: ${CPPPATH}, compiler: ${compiler}")).to eq([
          "cflag: -Wall, cpppath: dir1, compiler: gcc",
          "cflag: -O2, cpppath: dir1, compiler: gcc",
          "cflag: -Wall, cpppath: dir2, compiler: gcc",
          "cflag: -O2, cpppath: dir2, compiler: gcc",
        ])
      end
      it "returns an empty string when a variable reference refers to a non-existent variable" do
        expect(v.expand_varref("${not_here}")).to eq("")
      end
      it "raises an error when a variable reference refers to an unhandled type" do
        expect { v.expand_varref("${hash}") }.to raise_error /I do not know how to expand a variable reference to a Hash/
      end
    end
  end
end
