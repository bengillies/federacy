require 'links/resolver'

module Links

  class Transcluder
    attr_accessor :space

    def initialize renderer, user, space
      @renderer = renderer
      @current_user = user
      @space = space
      @transcluding = []
    end

    def transcluding?
      @transcluding.length > 0
    end

    def retrieve_link links, link_str
      links[:links].find do |link|
        link[:link] == link_str
      end
    end

    def transclude text, links
      current_space = @space
      text.gsub(/#{links[:start]}(.*?)#{links[:end]}/m) do |match|
        transclusion = $1
        begin
          new_space, tiddler = Links::Resolver.new(@current_user, current_space)
            .resolve(retrieve_link(links, $1[/href="([^"]+)"/m, 1]))

          unless @transcluding.include?(tiddler.id)
            @transcluding << tiddler.id
            @renderer = @renderer.clone(new_space, self)
            transclusion = @renderer.render_tiddler(tiddler, content_type: tiddler.content_type)
            @space = current_space
          end
        rescue SpaceNotFound, TiddlerNotFound
        end

        "<div class=\"transclusion\">#{transclusion}</div>"
      end
    end

  end

end
