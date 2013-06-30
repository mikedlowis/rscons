class Module
  def short_name
    name.split(':').last
  end
end
