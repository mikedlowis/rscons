require 'yaml'
require 'fileutils'
require 'digest/md5'
require 'set'
require 'rscons/version'

module Rscons
  # Example cache:
  # {
  #   version: '1.2.3',
  #   targets: {
  #     'program' => {
  #       'checksum' => 'A1B2C3D4',
  #       'command' => ['gcc', '-o', 'program', 'program.o'],
  #       'deps' => [
  #         {
  #           'fname' => 'program.o',
  #           'checksum' => '87654321',
  #         }
  #       ],
  #     }
  #     'program.o' => {
  #       'checksum' => '87654321',
  #       'command' => ['gcc', '-c', '-o', 'program.o', 'program.c'],
  #       'deps' => [
  #         {
  #           'fname' => 'program.c',
  #           'checksum' => '456789ABC',
  #         },
  #         {
  #           'fname' => 'program.h',
  #           'checksum' => '7979764643',
  #         }
  #       ]
  #     }
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
      @cache = YAML.load(File.read(CACHE_FILE)) rescue {
        targets: {},
        version: VERSION,
      }
      @lookup_checksums = {}
    end

    def write
      File.open(CACHE_FILE, 'w') do |fh|
        fh.puts(YAML.dump(@cache))
      end
    end

    def up_to_date?(target, command, deps, options = {})
      # target file must exist on disk
      return false unless File.exists?(target)

      # target must be registered in the cache
      return false unless @cache[:targets].has_key?(target)

      # command used to build target must be identical
      return false unless @cache[:targets][target][:command] == command

      cached_deps = @cache[:targets][target][:deps].map { |dc| dc[:fname] }
      if options[:strict_deps]
        # depedencies passed in must exactly equal those in the cache
        return false unless deps == cached_deps
      else
        # all dependencies passed in must exist in cache (but cache may have more)
        return false unless (Set.new(deps) - Set.new(cached_deps)).empty?
      end

      # all cached dependencies must have their checksums match
      @cache[:targets][target][:deps].map do |dep_cache|
        dep_cache[:checksum] == lookup_checksum(dep_cache[:fname])
      end.all?
    end

    def register_build(target, command, deps)
      @cache[:targets][target] = {
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
