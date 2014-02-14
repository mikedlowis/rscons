# Standard Ruby String class.
class String
  # Return a new string with the suffix (dot character and extension) changed
  # to the given suffix.
  # @param suffix [String] The new suffix.
  def set_suffix(suffix = '')
    sub(/\.[^.]*$/, suffix)
  end
end
