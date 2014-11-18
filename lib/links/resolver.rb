module Links

  class TiddlerNotFound < StandardError; end
  class SpaceNotFound < StandardError; end

  class Resolver
    attr_reader :user

    def initialize user, space=nil
      @current_user = user
      @space = space
    end

    def resolve link

      if link[:space_name] || link[:space]
        space = resolve_space_by_name(link[:space_name] || link[:space])
        unless space
          raise SpaceNotFound
        end
      else
        space = resolve_space_by_id(link[:space_id] || @space.id)
      end

      if link[:username] || link[:user]
        @user = User.find_by_name(link[:username] || link[:user])
      end
      space = visible_to_users(space, @user)

      if space && (link[:tiddler_title] || link[:tiddler])
        tiddler = resolve_tiddler(space, link[:tiddler_title] || link[:tiddler])

        unless tiddler
          raise TiddlerNotFound
        end

        return [space, tiddler]
      end

      return space
    end

    def resolve_space_by_name space_name
      Space.find_by_name(space_name.to_s)
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
      space.tiddlers.by_title(tiddler_title.to_s).first
    end

  end

end
