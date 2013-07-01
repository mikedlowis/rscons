class String
  def has_suffix?(suffix)
    suffix = [suffix] if suffix.is_a?(String)
    suffix.find {|s| self =~ /#{s}$/}
  end

  def set_suffix(suffix = '')
    sub(/\.[^.]*$/, suffix)
  end
end
