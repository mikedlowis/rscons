# Standard Ruby Module class.
class Module
  # @return the base module name (not the fully qualified name)
  def short_name
    name.split(':').last
  end
end
