require 'fileutils'

describe Rscons do
  before(:all) do
    FileUtils.rm_rf('build_tests_run')
    FileUtils.cp_r('build_tests', 'build_tests_run')
    @owd = Dir.pwd
  end

  after(:each) do
    Dir.chdir(@owd)
  end

  def test_dir(build_test_directory)
    dir = "build_tests_run/#{build_test_directory}"
    if File.exists?('build.rb')
      system("ruby -r rscons -C #{dir} build.rb")
    end
    Dir.chdir(dir)
  end

  ###########################################################################
  # Tests
  ###########################################################################

  it 'builds a C program with one source file' do
    test_dir('simple')
    File.exists?('simple.o').should be_true
    `./simple`.should == "This is a simple C program\n"
  end
end
