class String
  def has_suffix?(suffix)
    if suffix
      suffix = [suffix] if suffix.is_a?(String)
      suffix.find {|s| self.end_with?(s)}
    end
  end

  def set_suffix(suffix = '')
    sub(/\.[^.]*$/, suffix)
  end
end
