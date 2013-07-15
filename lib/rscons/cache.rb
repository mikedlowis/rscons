require 'yaml'
require 'fileutils'
require 'digest/md5'
require 'set'

module Rscons
  # Example cache:
  # {
  #   'program' => {
  #     'checksum' => 'A1B2C3D4',
  #     'command' => ['gcc', '-o', 'program', 'program.o'],
  #     'deps' => [
  #       {
  #         'fname' => 'program.o',
  #         'checksum' => '87654321',
  #       }
  #     ],
  #   }
  #   'program.o' => {
  #     'checksum' => '87654321',
  #     'command' => ['gcc', '-c', '-o', 'program.o', 'program.c'],
  #     'deps' => [
  #       {
  #         'fname' => 'program.c',
  #         'checksum' => '456789ABC',
  #       },
  #       {
  #         'fname' => 'program.h',
  #         'checksum' => '7979764643',
  #       }
  #     ]
  #   }
  # }
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
      @lookup_checksums = {}
    end

    def write
      File.open(CACHE_FILE, 'w') do |fh|
        fh.puts(YAML.dump(@cache))
      end
    end

    def up_to_date?(target, command, deps)
      # target file must exist on disk
      return false unless File.exists?(target)
      # target must be registered in the cache
      return false unless @cache.has_key?(target)
      # command line used to build target must be identical
      return false unless @cache[target][:command] == command
      # all dependencies passed in must exist in cache (but cache may have more)
      cached_deps = @cache[target][:deps].map { |dc| dc[:fname] }
      return false unless (Set.new(deps) - Set.new(cached_deps)).empty?
      # all cached dependencies must have their checksums match
      @cache[target][:deps].map do |dep_cache|
        dep_cache[:checksum] == lookup_checksum(dep_cache[:fname])
      end.all?
    end

    def register_build(target, command, deps)
      @cache[target] = {
        command: command,
        checksum: calculate_checksum(target),
        deps: deps.map do |dep|
          {
            fname: dep,
            checksum: lookup_checksum(dep),
          }
        end
      }
    end

    # Private Instance Methods
    private

    def lookup_checksum(file)
      @lookup_checksums[file] || calculate_checksum(file)
    end

    def calculate_checksum(file)
      @lookup_checksums[file] = Digest::MD5.hexdigest(File.read(file)).encode(__ENCODING__) rescue ''
    end
  end
end
