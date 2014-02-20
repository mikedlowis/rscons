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
Rscons::Environment.new do |env|
  env["CFLAGS"] << "-Wall"
  env.Program("program", Dir["**/*.c"])
end
```

### Example: Building a D Program

```ruby
Rscons::Environment.new do |env|
  env["DFLAGS"] << "-Wall"
  env.Program("program", Dir["**/*.d"])
end
```

### Example: Cloning an Environment

```ruby
main_env = Rscons::Environment.new do |env|
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

Custom builders are implemented as classes which extend from `Rscons::Builder`.
The builder must have a `run` method which is called to invoke the builder.
The `run` method should return the name of the target built on success, and
`false` on failure.

```ruby
class GenerateFoo < Rscons::Builder
  def run(target, sources, cache, env, vars)
    cache.mkdir_p(File.dirname(target))
    File.open(target, "w") do |fh|
      fh.puts <<EOF
#define GENERATED 42
EOF
    end
    target
  end
end

Rscons::Environment.new do |env|
  env.add_builder(GenerateFoo.new)
  env.GenerateFoo("foo.h", [])
  env.Program("a.out", Dir["*.c"])
end
```

### Example: Custom Builder That Only Regenerates When Necessary

```ruby
class CmdBuilder < Rscons::Builder
  def run(target, sources, cache, env, vars)
    cmd = ["cmd", "-i", sources.first, "-o", target]
    unless cache.up_to_date?(target, cmd, sources, env)
      cache.mkdir_p(File.dirname(target))
      system(cmd)
      cache.register_build(target, cmd, sources, env)
    end
    target
  end
end

Rscons::Environment.new do |env|
  env.add_builder(CmdBuilder.new)
  env.CmdBuilder("foo.gen", "foo_gen.cfg")
end
```

### Example: Custom Builder That Generates Multiple Output Files

```ruby
class CModuleGenerator < Rscons::Builder
  def run(target, sources, cache, env, vars)
    c_fname = target
    h_fname = target.sub(/\.c$/, ".h")
    cmd = ["generate_c_and_h", sources.first, c_fname, h_fname]
    unless cache.up_to_date?([c_fname, h_fname], cmd, sources, env)
      cache.mkdir_p(File.dirname(target))
      system(cmd)
      cache.register_build([c_fname, h_fname], cmd, sources, env)
    end
    target
  end
end

Rscons::Environment.new do |env|
  env.add_builder(CModuleGenerator.new)
  env.CModuleGenerator("build/foo.c", "foo_gen.cfg")
end
```

### Example: Custom Builder Using Builder#standard_build()

The `standard_build` method from the `Rscons::Builder` base class can be used
when the builder needs to execute a system command to produce the target file.
The `standard_build` method will return the correct value so its return value
can be used as the return value from the `run` method.

```ruby
class CmdBuilder < Rscons::Builder
  def run(target, sources, cache, env, vars)
    cmd = ["cmd", "-i", sources.first, "-o", target]
    standard_build("CmdBld #{target}", target, cmd, sources, env, cache)
  end
end

Rscons::Environment.new do |env|
  env.add_builder(CmdBuilder.new)
  env.CmdBuilder("foo.gen", "foo_gen.cfg")
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

Each build hook block will be invoked for every build operation, so the block
should test the target or sources if its action should only apply to some
subset of build targets or source files.

The `build_op` parameter to the build hook block is a Hash describing the
build operation with the following keys:
* `:builder` - `Builder` instance in use
* `:target` - `String` name of the target file
* `:sources` - `Array` of the source files
* `:vars` - `Rscons::VarSet` containing the construction variables to use
The build hook can overwrite entries in `build_op[:vars]` to alter the
construction variables in use for this specific build operation.

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

If you want to create an Environment that does not contain any builders,
you can use the `exclude_builders` key to the Environment constructor.

### Managing Environments

An Rscons::Environment consists of:

* a collection of construction variables
* a collection of builders
* a mapping of build directories from source directories
* a default build root to apply if no build directories are matched
* a collection of targets to build
* a collection of build hooks

When cloning an environment, the construction variables and builders are
cloned, but the new environment does not inherit any of the targets, build
hooks, build directories, or the build root from the source environment.

Cloned environments contain "deep copies" of construction variables.
For example, in:

```ruby
base_env = Rscons::Environment.new
base_env["CPPPATH"] = ["one", "two"]
cloned_env = base_env.clone
cloned_env["CPPPATH"] << "three"
```

`base_env["CPPPATH"]` will not include "three".

### Construction Variable Naming

* uppercase strings - the default construction variables that Rscons uses
* lowercase symbols - Rscons options
* lowercase strings - reserved as user-defined construction variables

### API documentation

Documentation for the complete Rscons API can be found at
http://rubydoc.info/github/holtrop/rscons/frames.

## Release Notes

### v1.2.0
- add :clone option to Environment#clone to control exactly which Environment attributes are cloned
- allow nil to be passed in to Environment#build_root=

### v1.1.0

- Change Cache#up_to_date?() and #register_build() to accept a single target
  file or an array of target file names

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
