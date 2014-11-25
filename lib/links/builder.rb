require_dependency 'links/resolver'
require_dependency 'markdown/link_extractor'

module Links

  class Builder
    def initialize root_url, space, user, old_revision
      @root_url = root_url
      @old_revision = old_revision
      @current_user = user
      @space = space
    end

    def create_links new_revision, body
      return unless body.linkable?

      new_revision = new_revision

      links = Markdown::LinkExtractor.new(body.text).extract_links

      old_links = @old_revision.links

      links.each do |link|
        revision_link = new_revision.revision_links.build(to_revision_link(link))

        old_link = find_matching_link(old_links, link)
        if old_link
          revision_link.user_id = old_link.user_id if old_link.user_id
          revision_link.space_id = old_link.space_id if old_link.space_id
          revision_link.tiddler = old_link.tiddler if old_link.tiddler
          revision_link.target = old_link.tiddler.current_revision if old_link.tiddler
        end

        if revision_link.target &&
            revision_link.target.id == @old_revision.id
          revision_link.target = new_revision
        else
          revision_link.target = revision_link.target &&
            revision_link.target.tiddler.current_revision
        end
      end

      new_revision.revision_links
    end

    # turn an extracted link into a link to an actual tiddler/space
    def to_revision_link link
      resolver = Links::Resolver.new(@root_url, @current_user, @space)
      unless link[:link]
        begin
          if link[:tiddler_title]
            space, tiddler = resolver.resolve(link)
          else
            space = resolver.resolve(link)
            tiddler = nil
          end
          user = resolver.user
        rescue SpaceNotFound, TiddlerNotFound, UserNotFound
          space = tiddler = user = nil
        end
      else
        space = tiddler = user = nil
        link = resolver.extract_link_info(link)
      end

      {
        start: link[:start],
        end:            link[:end],
        link_type:      link[:link_type],
        link:           link[:link],
        tiddler_title:  link[:tiddler_title],
        space_name:     link[:space_name],
        user_name:      link[:user_name],
        space:          space,
        target:         tiddler && tiddler.current_revision,
        user:           user,
        title:          link[:title],
        space_id:       link[:space_id],
        tiddler_id:     link[:tiddler_id],
        target_id:      link[:target_id]
      }
    end

    # Find a link from old_links that exactly matches the new link provided. If
    # we find a match, then we assume that we want to point to the same place
    # rather than trying to find a tiddler all over again.
    def find_matching_link old_links, link
      return false if link[:link]
      return false unless link[:tiddler_title] || link[:space_name]

      old_links.find do |old_link|
        link[:tiddler_title] == old_link.tiddler_title &&
          link[:space_name] == old_link.space_name &&
          link[:user_name] == old_link.user_name &&
          link[:title] == old_link.title &&
          link[:link_type].to_s == old_link.link_type.to_s
      end
    end
  end

end
