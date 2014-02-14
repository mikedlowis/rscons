# Standard Ruby String class.
class String
  # Return a new string with the suffix (dot character and extension) changed
  # to the given suffix.
  # @param suffix [String] The new suffix.
  def set_suffix(suffix = '')
    sub(/\.[^.]*$/, suffix)
  end

  # Return whether the string represents an absolute filesystem path
  def absolute_path?
    self =~ %r{^(/|\w:[\\/])}
  end
end
