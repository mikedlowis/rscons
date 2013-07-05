require 'yaml'
require 'fileutils'
require 'digest/md5'

module Rscons
  class Cache
    # Constants
    CACHE_FILE = '.rsconscache'

    # Class Methods
    def self.clear
      FileUtils.rm_f(CACHE_FILE)
    end

    # Instance Methods
    def initialize
      @cache = YAML.load(File.read(CACHE_FILE)) rescue {}
    end

    def write
      File.open(CACHE_FILE, 'w') do |fh|
        fh.puts(YAML.dump(@cache))
      end
    end

    def up_to_date?(file, deps = nil)
      # TODO
    end

    def register_build(target, deps)
      # TODO
    end

    # Private Instance Methods
    private

    def calculate_checksum(file)
      Digest::MD5.hexdigest(File.read(file)).encode(__ENCODING__)
    end
  end
end
