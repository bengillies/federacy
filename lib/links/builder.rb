# TODO:
#  - make renderer use new RevisionLinks
#  - add in backlinks to tiddler/revision view
#  - use shortlinks if space/tiddler property is nil
#  - make shortlinks open up /new page if 404

require 'links/resolver'

module Links

  class Builder
    def initialize old_revision, new_revision
      @old_revision = old_revision
      @new_revision = new_revision
      @current_user = old_revision.user
      @space = old_revision.tiddler.space
    end

    def create_links body
      return unless body.linkable?

      links = Markdown::LinkExtractor.new(body.text).extract_links

      old_links = @old_revision.links

      links.each do |link|
        old_link = find_matching_link(old_links, link)
        if old_link
          revision_link = @new_revision.revision_links.build(old_link.as_json)
          revision_link.start = link[:start]
          revision_link.end = link[:end]
          revision_link.id = nil
        else
          revision_link = @new_revision.revision_links.build(to_revision_link(link))
        end

        if revision_link.tiddler &&
            revision_link.tiddler.id == @old_revision.id
          revision_link.tiddler = @new_revision
        else
          revision_link.tiddler = revision_link.tiddler &&
            revision_link.tiddler.tiddler.current_revision
        end
      end

      @new_revision.revision_links
    end

    # turn an extracted link into a link to an actual tiddler/space
    def to_revision_link link
      unless link[:link]
        begin
          resolver = Links::Resolver.new(@current_user, @space)
          if link[:tiddler]
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
      end

      {
        start: link[:start],
        end: link[:end],
        link_type: link[:link_type],
        link: link[:link],
        tiddler_title: link[:tiddler],
        space_name: link[:space],
        user_name: link[:user],
        space: space,
        tiddler: tiddler && tiddler.current_revision,
        user: user,
        title: link[:title],
      }
    end

    # Find a link from old_links that exactly matches the new link provided. If
    # we find a match, then we assume that we want to point to the same place
    # rather than trying to find a tiddler all over again.
    def find_matching_link old_links, link
      return false if link[:link]
      return false unless link[:tiddler] || link[:space]

      old_links.find do |old_link|
        link[:tiddler] == old_link.tiddler_title &&
          link[:space] == old_link.space_name &&
          link[:user] == old_link.user_name &&
          link[:title] == old_link.title
      end
    end
  end

end
