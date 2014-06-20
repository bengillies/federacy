require 'linking'

class LinkExtractor
  include Linking

  def initialize space, current_user
    @space = space
    @current_user = current_user
  end

  def find_links text, previous_revision_links = {}
    new_links = []
    TRANSCLUSIONS.each do |regex, meta|
      each_match(regex, text) do |match|
        new_links << build_link match, meta, previous_revision_links
      end
    end

    LINKS.each do |regex, meta|
      each_match(regex, text) do |match|
        new_links << build_link match, meta, previous_revision_links
      end
    end
    new_links
  end

  def build_link link_match, meta, previous
    link = {
      link_str: match[0],
      link_type: meta[:type],
      title: match[meta[:title]],
    }

    link[:tiddler_title] = match[meta[:tiddler_title]] if meta[:tiddler_title]
    link[:space_name] = match[meta[:space_name]] if meta[:space_name]
    link[:user_name] = match[meta[:user_name]] if meta[:user_name]

    old_version_of_link = find_old_link_from_new link[:title], previous_revision_links
    return old_version_of_link if old_version_of_link

    link[:tiddler_id], link[:space_id] = lookup_canonical_reference link
    link
  end

  def find_old_link_from_new link_str, previous_revision_links
    previous_revision_links.find {|prev| prev[:link_str] == link_str }
  end

  def lookup_canonical_reference link_obj
    
  end

end
