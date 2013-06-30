module Rscons
  class Environment
    class << self
      alias_method :orig_new, :new
    end

    def self.new(*args)
      e = Environment.orig_new(*args)
      if block_given?
        yield e
        e.process
      end
      e
    end

    # Initialize a newly constructed Environment object
    # === Arguments
    # +variables+ _Hash_ ::
    #   the variables hash can contain both construction variables, which are
    #   uppercase strings (such as "CC" or "LDFLAGS"), and rscons options,
    #   which are lowercase symbols (such as :echo).
    def initialize(variables = {})
      @variables = variables
      @targets = {}
      @builders = {}
      @variables[:exclude_builders] ||= []
      unless @variables[:exclude_builders] == :all
        exclude_builders = Set.new(@variables[:exclude_builders] || [])
        DEFAULT_BUILDERS.each do |builder_class|
          unless exclude_builders.include?(builder_class.short_name)
            add_builder(builder_class)
          end
        end
      end
      (@variables[:builders] || []).each do |builder_class|
        add_builder(builder_class)
      end
    end

    def add_builder(builder_class)
      @builders[builder_class.short_name] = builder_class
    end

    def process
    end

    alias_method :orig_method_missing, :method_missing
    def method_missing(method, *args)
      if @builders.has_key?(method.to_s)
        target, source, *rest = args
        @targets[target] = {
          builder: method.to_s,
          source: source,
          args: rest,
        }
      else
        orig_method_missing(method, *args)
      end
    end
  end
end
