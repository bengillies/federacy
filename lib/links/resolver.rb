module Links

  class RevisionNotFound < StandardError; end
  class TiddlerNotFound < StandardError; end
  class SpaceNotFound < StandardError; end
  class UserNotFound < StandardError; end

  class Resolver
    attr_reader :user, :found_space

    def initialize opts
      @root_url = opts[:root_url]
      @current_user = opts[:user]
      @space = opts[:space] || nil
      @include_revision = opts[:include_revision] || false
    end

    # is the given string a tiddler, or a link
    def self.tiddler_name? link
      not (link.start_with?('/') || /([A-Za-z]{3,9}:(?:\/\/)?)/.match(link))
    end

    def local? url
      url.start_with?('/') || url.start_with?(@root_url)
    end

    def path url
      URI.parser.parse(url).path
    end

    # turn a link to a url into a link obj that, if possible, also includes
    # tiddler/space info
    def extract_link_info link_obj
      # match all shortlinks and standard links to tiddlers, spaces and revisions
      # using named captures. Don't match links to lists of things.
      link_matcher = /^(?:(?:(?:(?:\/u\/(?<user_name>[^\/\?]+))\/(?<space_name>[^\/\?]+)(?:\/(?<tiddler_title>[^\/\?\.]+))?)|(?:\/s\/(?<space_name>[^\/\?]+)(?:\/(?<tiddler_title>[^\/\?\.]+))?)|(?:\/spaces\/(?<space_id>[^\/\?]+)\/t\/(?<tiddler_title>[^\/\?\.]+)))|(?:\/spaces\/(?<space_id>[^\/\?\.]+)(?:\/tiddlers\/(?<tiddler_id>[^\/\?\.]+)(?:\/revisions\/(?<target_id>[^\/\?\.]+))?)?))/

      link = link_obj[:link]
      return link_obj unless local? link
      link = path(link)
      match = link_matcher.match(link)

      if match
        link_obj.clone.merge(
          tiddler_title: match[:tiddler_title],
          space_name:    match[:space_name],
          user_name:     match[:user_name],
          tiddler_id:    match[:tiddler_id] && match[:tiddler_id].to_i,
          space_id:      match[:space_id] && match[:space_id].to_i,
          target_id:     match[:target_id] && match[:target_id].to_i
        )
      else
        link_obj.clone
      end
    end

    def resolve link
      if link[:space_id]
        @found_space = space = resolve_space_by_id(link[:space_id])
      elsif link[:space_name]
        @found_space = space = resolve_space_by_name(link[:space_name])
        unless space
          raise SpaceNotFound
        end
      else
        @found_space = space = resolve_space_by_id(@space.id)
      end

      if link[:user_name]
        @user = User.find_by_name(link[:user_name])
        unless @user
          raise UserNotFound
        end
      end
      space = visible_to_users(space, @user)

      if space && (link[:tiddler_title] || link[:tiddler_id])
        tiddler = resolve_tiddler(space, link)

        unless tiddler
          raise TiddlerNotFound
        end

        if @include_revision
          revision = resolve_revision(tiddler, link)
          return [space, tiddler, revision]
        end

        return [space, tiddler]
      end

      return space
    end

    def resolve_space_by_name space_name
      Space.find_by_name(space_name)
    end

    def resolve_space_by_id space_id
      begin
        Space.find(space_id)
      rescue ActiveRecord::RecordNotFound
        raise SpaceNotFound
      end
    end

    def visible_to_users space, user
      users = space.users
      users.include?(@current_user)
      if user
        users.include?(user)
      else
        space
      end
      space
    end

    def resolve_tiddler space, link
      begin
        return space.tiddlers.find(link[:tiddler_id]) if link[:tiddler_id]
        space.tiddlers.by_title(link[:tiddler_title]).first
      rescue ActiveRecord::RecordNotFound
        raise TiddlerNotFound
      end
    end

    def resolve_revision tiddler, link
      begin
        tiddler.revisions.find(link[:target_id])
      rescue ActiveRecord::RecordNotFound
        raise RevisionNotFound
      end
    end

  end

end
