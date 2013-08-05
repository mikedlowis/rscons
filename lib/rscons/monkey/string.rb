# Standard Ruby String class.
class String
  # Check if the given string ends with any of the supplied suffixes
  # @param suffix [String, Array] The suffix to look for.
  # @return a true value if the string ends with one of the suffixes given.
  def has_suffix?(suffix)
    if suffix
      suffix = [suffix] if suffix.is_a?(String)
      suffix = suffix.flatten
      suffix.find {|s| self.end_with?(s)}
    end
  end

  # Return a new string with the suffix (dot character and extension) changed
  # to the given suffix.
  # @param suffix [String] The new suffix.
  def set_suffix(suffix = '')
    sub(/\.[^.]*$/, suffix)
  end
end
