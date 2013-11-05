require 'fileutils'

describe Rscons do
  before(:all) do
    FileUtils.rm_rf('build_tests_run')
    @owd = Dir.pwd
  end

  after(:each) do
    Dir.chdir(@owd)
    FileUtils.rm_rf('build_tests_run')
  end

  def build_testdir(build_script = "build.rb")
    if File.exists?(build_script)
      build_rb = File.read(build_script)
      File.open(build_script, "w") do |fh|
        fh.puts(<<EOF + build_rb)
require "simplecov"

SimpleCov.start do
  root("#{@owd}")
  command_name("build_test_#{@build_test_name}")
  add_filter("spec")
end

require "rscons"
EOF
      end
      IO.popen(%{ruby -I #{@owd}/lib #{build_script}}) do |io|
        io.readlines.reject do |line|
          line =~ /^Coverage report/
        end
      end.map(&:strip)
    end
  end

  def test_dir(build_test_directory, build_script = "build.rb")
    @build_test_name = build_test_directory
    FileUtils.cp_r("build_tests/#{build_test_directory}", 'build_tests_run')
    Dir.chdir("build_tests_run")
    build_testdir(build_script)
  end

  def file_sub(fname)
    contents = File.read(fname)
    replaced = ''
    contents.each_line do |line|
      replaced += yield(line)
    end
    File.open(fname, 'w') do |fh|
      fh.write(replaced)
    end
  end

  ###########################################################################
  # Tests
  ###########################################################################

  it 'builds a C program with one source file' do
    test_dir('simple')
    File.exists?('simple.o').should be_true
    `./simple`.should == "This is a simple C program\n"
  end

  it 'prints commands as they are executed' do
    lines = test_dir('simple')
    lines.should == [
      'gcc -c -o simple.o -MMD -MF simple.mf simple.c',
      'gcc -o simple simple.o',
    ]
  end

  it 'prints short representations of the commands being executed' do
    lines = test_dir('header')
    lines.should == [
      'CC header.o',
      'LD header',
    ]
  end

  it 'builds a C program with one source file and one header file' do
    test_dir('header')
    File.exists?('header.o').should be_true
    `./header`.should == "The value is 2\n"
  end

  it 'rebuilds a C module when a header it depends on changes' do
    test_dir('header')
    `./header`.should == "The value is 2\n"
    file_sub('header.h') {|line| line.sub(/2/, '5')}
    build_testdir
    `./header`.should == "The value is 5\n"
  end

  it 'does not rebuild a C module when its dependencies have not changed' do
    lines = test_dir('header')
    `./header`.should == "The value is 2\n"
    lines.should == [
      'CC header.o',
      'LD header',
    ]
    lines = build_testdir
    lines.should == []
  end

  it "does not rebuild a C module when only the file's timestampe has changed" do
    lines = test_dir('header')
    `./header`.should == "The value is 2\n"
    lines.should == [
      'CC header.o',
      'LD header',
    ]
    file_sub('header.c') {|line| line}
    lines = build_testdir
    lines.should == []
  end

  it 're-links a program when the link flags have changed' do
    lines = test_dir('simple')
    lines.should == [
      'gcc -c -o simple.o -MMD -MF simple.mf simple.c',
      'gcc -o simple simple.o',
    ]
    file_sub('build.rb') {|line| line.sub(/.*CHANGE.FLAGS.*/, '  env["LIBS"] += ["c"]')}
    lines = build_testdir
    lines.should == ['gcc -o simple simple.o -lc']
  end

  it 'builds object files in a different build directory' do
    lines = test_dir('build_dir')
    `./build_dir`.should == "Hello from two()\n"
    File.exists?('build_one/one.o').should be_true
    File.exists?('build_two/two.o').should be_true
  end

  it 'cleans built files' do
    lines = test_dir('build_dir')
    `./build_dir`.should == "Hello from two()\n"
    File.exists?('build_one/one.o').should be_true
    File.exists?('build_two/two.o').should be_true
    Rscons.clean
    File.exists?('build_one/one.o').should be_false
    File.exists?('build_two/two.o').should be_false
    File.exists?('build_one').should be_false
    File.exists?('build_two').should be_false
    File.exists?('src/one/one.c').should be_true
  end

  it 'does not clean created directories if other non-rscons-generated files reside there' do
    lines = test_dir('build_dir')
    `./build_dir`.should == "Hello from two()\n"
    File.exists?('build_one/one.o').should be_true
    File.exists?('build_two/two.o').should be_true
    File.open('build_two/tmp', 'w') { |fh| fh.puts "dum" }
    Rscons.clean
    File.exists?('build_one/one.o').should be_false
    File.exists?('build_two/two.o').should be_false
    File.exists?('build_one').should be_false
    File.exists?('build_two').should be_true
    File.exists?('src/one/one.c').should be_true
  end

  it 'allows Ruby classes as custom builders to be used to construct files' do
    lines = test_dir('custom_builder')
    lines.should == ['CC program.o', 'LD program']
    File.exists?('inc.h').should be_true
    `./program`.should == "The value is 5678\n"
  end

  it 'allows cloning Environment objects' do
    lines = test_dir('clone_env')
    lines.should == [
      %q{gcc -c -o debug/program.o -MMD -MF debug/program.mf '-DSTRING="Debug Version"' -O2 src/program.c},
      %q{gcc -o program-debug debug/program.o},
      %q{gcc -c -o release/program.o -MMD -MF release/program.mf '-DSTRING="Release Version"' -O2 src/program.c},
      %q{gcc -o program-release release/program.o},
    ]
  end

  it 'builds a C++ program with one source file' do
    test_dir('simple_cc')
    File.exists?('simple.o').should be_true
    `./simple`.should == "This is a simple C++ program\n"
  end

  it 'allows overriding construction variables for individual builder calls' do
    lines = test_dir('two_sources')
    lines.should == [
      'gcc -c -o one.o -MMD -MF one.mf -DONE one.c',
      'gcc -c -o two.o -MMD -MF two.mf two.c',
      'gcc -o two_sources one.o two.o',
    ]
    File.exists?('two_sources').should be_true
    `./two_sources`.should == "This is a C program with two sources.\n"
  end

  it 'builds a static library archive' do
    lines = test_dir('library')
    lines.should == [
      'gcc -c -o one.o -MMD -MF one.mf -Dmake_lib one.c',
      'gcc -c -o two.o -MMD -MF two.mf -Dmake_lib two.c',
      'ar rcs lib.a one.o two.o',
      'gcc -c -o three.o -MMD -MF three.mf three.c',
      'gcc -o library lib.a three.o',
    ]
    File.exists?('library').should be_true
    `ar t lib.a`.should == "one.o\ntwo.o\n"
  end

  it 'supports tweakers to override construction variables' do
    lines = test_dir("build_dir", "tweaker_build.rb")
    `./tweaker`.should == "Hello from two()\n"
    lines.should =~ [
      'gcc -c -o build_one/one.o -MMD -MF build_one/one.mf -Isrc/one/ -Isrc/two/ -O1 src/one/one.c',
      'gcc -c -o build_two/two.o -MMD -MF build_two/two.mf -Isrc/one/ -Isrc/two/ -O2 src/two/two.c',
      'gcc -o tweaker build_one/one.o build_two/two.o',
    ]
  end
end
