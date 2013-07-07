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

  def test_dir(build_test_directory)
    FileUtils.cp_r("build_tests/#{build_test_directory}", 'build_tests_run')
    Dir.chdir("build_tests_run")
    if File.exists?("build.rb")
      system("ruby -I #{@owd}/lib -r rscons build.rb")
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

  it 'builds a C program with one source file and one header file' do
    test_dir('header')
    File.exists?('header.o').should be_true
    `./header`.should == "The value is 2\n"
  end
end
