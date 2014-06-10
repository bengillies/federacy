class TagList < Array
  def to_s
    tag_string = ""
    each do |tag|
      if /\s/.match tag.name
        tag_string += " [[#{tag}]]"
      else
        tag_string += " #{tag}"
      end
    end
    tag_string.strip
  end

  def self.from_s tags
    self.new tags.scan(/(?:(?:^| )\[\[([^\]\]]+)\]\](?: |$)|([^\s]+))/).flatten.compact.uniq
  end
end
