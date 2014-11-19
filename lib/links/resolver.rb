module Links

  class TiddlerNotFound < StandardError; end
  class SpaceNotFound < StandardError; end
  class UserNotFound < StandardError; end

  class Resolver
    attr_reader :user

    def initialize user, space=nil
      @current_user = user
      @space = space
    end

    # is the given string a tiddler, or a link
    def self.tiddler_name? link
      not (link.start_with?('/') || /([A-Za-z]{3,9}:(?:\/\/)?)/.match(link))
    end

    def resolve link

      if link[:space_name]
        space = resolve_space_by_name(link[:space_name])
        unless space
          raise SpaceNotFound
        end
      else
        space = resolve_space_by_id(link[:space_id] || @space.id)
      end

      if link[:user_name]
        @user = User.find_by_name(link[:user_name])
        unless @user
          raise UserNotFound
        end
      end
      space = visible_to_users(space, @user)

      if space && (link[:tiddler_title])
        tiddler = resolve_tiddler(space, link[:tiddler_title])

        unless tiddler
          raise TiddlerNotFound
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

    def resolve_tiddler space, tiddler_title
      space.tiddlers.by_title(tiddler_title).first
    end

  end

end
