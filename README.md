# Rscons

Software construction library inspired by SCons and implemented in Ruby

[![Gem Version](https://badge.fury.io/rb/rscons.png)](http://badge.fury.io/rb/rscons)

## Installation

Add this line to your application's Gemfile:

    gem "rscons"

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rscons

## Usage

Rscons is a Ruby library.
It can be called from a standalone Ruby script or it can be used with rake and
called from your Rakefile.

### Example: Building a C Program

```ruby
RScons::Environment.new do |env|
  env["CFLAGS"] << "-Wall"
  env.Program("program", Dir["**/*.c"])
end
```

### Example: Building a D Program

```ruby
RScons::Environment.new do |env|
  env["DFLAGS"] << "-Wall"
  env.Program("program", Dir["**/*.d"])
end
```

### Example: Cloning an Environment

```ruby
main_env = RScons::Environment.new do |env|
  # Store object files from sources under "src" in "build/main"
  env.build_dir("src", "build/main")
  env["CFLAGS"] = ["-DSOME_DEFINE", "-O3"]
  env["LIBS"] = ["SDL"]
  env.Program("program", Dir["src/**/*.cc"])
end

debug_env = main_env.clone do |env|
  # Store object files from sources under "src" in "build/debug"
  env.build_dir("src", "build/debug")
  env["CFLAGS"] -= ["-O3"]
  env["CFLAGS"] += ["-g", "-O0"]
  env.Program("program-debug", Dir["src/**/*.cc"])
end
```

### Example: Custom Builder

```ruby
class GenerateFoo < Rscons::Builder
  def run(target, sources, cache, env, vars)
    File.open(target, "w") do |fh|
      fh.puts <<EOF
#define GENERATED 42
EOF
    end
  end
end

Rscons::Environment.new do |env|
  env.GenerateFoo("foo.h", [])
  env.Program("a.out", Dir["*.c"])
end
```

### Example: Using different compilation flags for some sources

```ruby
Rscons::Environment.new do |env|
  env["CFLAGS"] = ["-O3", "-Wall", "-DDEFINE"]
  env.add_build_hook do |build_op|
    if build_op[:target] =~ %r{build/third-party}
      build_op[:vars]["CFLAGS"] -= ["-Wall"]
    end
  end
  env.build_dir("src", "build")
  env.Program("program", Dir["**/*.cc"])
end
```

### Example: Creating a static library

```ruby
Rscons::Environment.new do |env|
  env.Library("mylib.a", Dir["src/**/*.c"])
end
```

## Details

### Default Builders

Rscons ships with a number of default builders:

* Library, which collects object files into a static library archive file
* Object, which compiles source files to produce an object file
* Program, which links object files to produce an executable

If you want to create an Environment that does not contain any (or select)
builders, you can use the `exclude_builders` key to the Environment constructor.

### Managing Environments

An Rscons::Environment consists of:

* a collection of construction variables
* a collection of builders
* a mapping of build directories
* a collection of targets to build
* a collection of build hooks

When cloning an environment, the construction variables, builders, and build
directories are cloned, but the new environment does not inherit any of the
targets or build hooks from the source environment.

Cloned environments contain "deep copies" of construction variables.
For example, in:

```ruby
base_env = Rscons::Environment.new
base_env["CPPPATH"] = ["one", "two"]
cloned_env = base_env.clone
cloned_env["CPPPATH"] << "three"
```

`base_env["CPPPATH"]` will not include "three".

### Construction Variables

The default construction variables that Rscons uses are named using uppercase
strings.
Rscons options are lowercase symbols.
Lowercase strings are reserved as user-defined construction variables.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
