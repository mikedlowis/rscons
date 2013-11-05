require 'fileutils'

describe Rscons do
  BUILD_TEST_RUN_DIR = "build_test_run"

  before(:all) do
    FileUtils.rm_rf(BUILD_TEST_RUN_DIR)
    @owd = Dir.pwd
  end

  before(:each) do
    @output = ""
    $stdout.stub(:write) do |content|
      @output += content
    end
    $stderr.stub(:write) do |content|
      @output += content
    end
  end

  after(:each) do
    Dir.chdir(@owd)
    FileUtils.rm_rf(BUILD_TEST_RUN_DIR)
  end

  def test_dir(build_test_directory)
    FileUtils.cp_r("build_tests/#{build_test_directory}", BUILD_TEST_RUN_DIR)
    Dir.chdir(BUILD_TEST_RUN_DIR)
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

  def lines
    @output.lines.map(&:rstrip).tap do |v|
      @output = ""
    end
  end

  ###########################################################################
  # Tests
  ###########################################################################

  it 'builds a C program with one source file' do
    test_dir('simple')
    Rscons::Environment.new do |env|
      env.Program('simple', Dir['*.c'])
    end
    File.exists?('simple.o').should be_true
    `./simple`.should == "This is a simple C program\n"
  end

  it 'prints commands as they are executed' do
    test_dir('simple')
    Rscons::Environment.new do |env|
      env["LD"] = "gcc"
      env.Program('simple', Dir['*.c'])
    end
    lines.should == [
      'gcc -c -o simple.o -MMD -MF simple.mf simple.c',
      'gcc -o simple simple.o',
    ]
  end

  it 'prints short representations of the commands being executed' do
    test_dir('header')
    Rscons::Environment.new(echo: :short) do |env|
      env.Program('header', Dir['*.c'])
    end
    lines.should == [
      'CC header.o',
      'LD header',
    ]
  end

  it 'builds a C program with one source file and one header file' do
    test_dir('header')
    Rscons::Environment.new(echo: :short) do |env|
      env.Program('header', Dir['*.c'])
    end
    File.exists?('header.o').should be_true
    `./header`.should == "The value is 2\n"
  end

  it 'rebuilds a C module when a header it depends on changes' do
    test_dir('header')
    env = Rscons::Environment.new(echo: :short) do |env|
      env.Program('header', Dir['*.c'])
    end
    `./header`.should == "The value is 2\n"
    file_sub('header.h') {|line| line.sub(/2/, '5')}
    env.process
    `./header`.should == "The value is 5\n"
  end

  it 'does not rebuild a C module when its dependencies have not changed' do
    test_dir('header')
    env = Rscons::Environment.new(echo: :short) do |env|
      env.Program('header', Dir['*.c'])
    end
    `./header`.should == "The value is 2\n"
    lines.should == [
      'CC header.o',
      'LD header',
    ]
    env.process
    lines.should == []
  end

  it "does not rebuild a C module when only the file's timestampe has changed" do
    test_dir('header')
    env = Rscons::Environment.new(echo: :short) do |env|
      env.Program('header', Dir['*.c'])
    end
    `./header`.should == "The value is 2\n"
    lines.should == [
      'CC header.o',
      'LD header',
    ]
    file_sub('header.c') {|line| line}
    env.process
    lines.should == []
  end

  it 're-links a program when the link flags have changed' do
    test_dir('simple')
    Rscons::Environment.new do |env|
      env.Program('simple', Dir['*.c'])
    end
    lines.should == [
      'gcc -c -o simple.o -MMD -MF simple.mf simple.c',
      'gcc -o simple simple.o',
    ]
    Rscons::Environment.new do |env|
      env["LIBS"] += ["c"]
      env.Program('simple', Dir['*.c'])
    end
    lines.should == ['gcc -o simple simple.o -lc']
  end

  it 'builds object files in a different build directory' do
    test_dir('build_dir')
    Rscons::Environment.new do |env|
      env.append('CPPPATH' => Dir['src/**/*/'])
      env.build_dir(%r{^src/([^/]+)/}, 'build_\\1/')
      env.Program('build_dir', Dir['src/**/*.c'])
    end
    `./build_dir`.should == "Hello from two()\n"
    File.exists?('build_one/one.o').should be_true
    File.exists?('build_two/two.o').should be_true
  end

  it 'cleans built files' do
    test_dir('build_dir')
    Rscons::Environment.new do |env|
      env.append('CPPPATH' => Dir['src/**/*/'])
      env.build_dir(%r{^src/([^/]+)/}, 'build_\\1/')
      env.Program('build_dir', Dir['src/**/*.c'])
    end
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
    test_dir('build_dir')
    Rscons::Environment.new do |env|
      env.append('CPPPATH' => Dir['src/**/*/'])
      env.build_dir(%r{^src/([^/]+)/}, 'build_\\1/')
      env.Program('build_dir', Dir['src/**/*.c'])
    end
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
   test_dir('custom_builder')
    class MySource < Rscons::Builder
      def run(target, sources, cache, env, vars = {})
        File.open(target, 'w') do |fh|
          fh.puts <<EOF
    #define THE_VALUE 5678
EOF
        end
        target
      end
    end

    Rscons::Environment.new(echo: :short) do |env|
      env.add_builder(MySource.new)
      env.MySource('inc.h', [])
      env.Program('program', Dir['*.c'])
    end

    lines.should == ['CC program.o', 'LD program']
    File.exists?('inc.h').should be_true
    `./program`.should == "The value is 5678\n"
  end

  it 'allows cloning Environment objects' do
    test_dir('clone_env')

    debug = Rscons::Environment.new do |env|
      env.build_dir('src', 'debug')
      env['CFLAGS'] = '-O2'
      env['CPPFLAGS'] = '-DSTRING="Debug Version"'
      env.Program('program-debug', Dir['src/*.c'])
    end

    release = debug.clone('CPPFLAGS' => '-DSTRING="Release Version"') do |env|
      env.build_dir('src', 'release')
      env.Program('program-release', Dir['src/*.c'])
    end

    lines.should == [
      %q{gcc -c -o debug/program.o -MMD -MF debug/program.mf '-DSTRING="Debug Version"' -O2 src/program.c},
      %q{gcc -o program-debug debug/program.o},
      %q{gcc -c -o release/program.o -MMD -MF release/program.mf '-DSTRING="Release Version"' -O2 src/program.c},
      %q{gcc -o program-release release/program.o},
    ]
  end

  it 'builds a C++ program with one source file' do
    test_dir('simple_cc')
    Rscons::Environment.new do |env|
      env.Program('simple', Dir['*.cc'])
    end
    File.exists?('simple.o').should be_true
    `./simple`.should == "This is a simple C++ program\n"
  end

  it 'allows overriding construction variables for individual builder calls' do
    test_dir('two_sources')
    Rscons::Environment.new(echo: :command) do |env|
      env.Object("one.o", "one.c", 'CPPFLAGS' => ['-DONE'])
      env.Program('two_sources', ['one.o', 'two.c'])
    end
    lines.should == [
      'gcc -c -o one.o -MMD -MF one.mf -DONE one.c',
      'gcc -c -o two.o -MMD -MF two.mf two.c',
      'gcc -o two_sources one.o two.o',
    ]
    File.exists?('two_sources').should be_true
    `./two_sources`.should == "This is a C program with two sources.\n"
  end

  it 'builds a static library archive' do
    test_dir('library')
    Rscons::Environment.new(echo: :command) do |env|
      env.Program('library', ['lib.a', 'three.c'])
      env.Library("lib.a", ['one.c', 'two.c'], 'CPPFLAGS' => ['-Dmake_lib'])
    end
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
    test_dir("build_dir")
    Rscons::Environment.new do |env|
      env.append('CPPPATH' => Dir['src/**/*/'])
      env.build_dir(%r{^src/([^/]+)/}, 'build_\\1/')
      env.add_tweaker do |build_op|
        if build_op[:target] =~ %r{build_one/.*\.o}
          build_op[:vars]["CFLAGS"] << "-O1"
        elsif build_op[:target] =~ %r{build_two/.*\.o}
          build_op[:vars]["CFLAGS"] << "-O2"
        end
      end
      env.Program('tweaker', Dir['src/**/*.c'])
    end
    `./tweaker`.should == "Hello from two()\n"
    lines.should =~ [
      'gcc -c -o build_one/one.o -MMD -MF build_one/one.mf -Isrc/one/ -Isrc/two/ -O1 src/one/one.c',
      'gcc -c -o build_two/two.o -MMD -MF build_two/two.mf -Isrc/one/ -Isrc/two/ -O2 src/two/two.c',
      'gcc -o tweaker build_one/one.o build_two/two.o',
    ]
  end
end
