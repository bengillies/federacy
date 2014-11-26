require_dependency 'links/resolver'

module Links

  class Transcluder
    attr_accessor :space

    def initialize root_url, renderer, user
      @renderer = renderer
      @root_url = root_url
      @current_user = user
      @transcluding = []
    end

    def transcluding?
      @transcluding.length > 0
    end

    def retrieve_link links, link_str
      links.find do |link|
        link[:link] == link_str
      end
    end

    def transclude opts
      text = opts[:text]
      links = opts[:links]
      tokens = opts[:tokens]
      include_revision = opts[:include_revision]

      current_space = @renderer.space
      text = text.gsub(/(?:<p>)?#{tokens[:start]}(?:<\/p>)?(.*?)(?:<p>)?#{tokens[:end]}(?:<\/p>)?/m) do |match|
        transclusion = $1
        begin
          new_space, tiddler, revision = Links::Resolver.new(
            root_url: @root_url,
            user: @current_user,
            space: current_space,
            include_revision: include_revision
          ).resolve(retrieve_link(links, $1[/href="([^"]+)"/m, 1]))

          tiddler = revision if include_revision

        rescue SpaceNotFound, TiddlerNotFound
          next wrap_transclusion transclusion
        rescue RevisionNotFound
          next wrap_transclusion(transclusion) if include_revision
        end

        unless @transcluding.include?(tiddler.id)
          @transcluding << tiddler.id
          @renderer = @renderer.clone(new_space, self)
          transclusion = @renderer.render_tiddler(tiddler, content_type: tiddler.content_type)
        end
        wrap_transclusion transclusion
      end
    end

    def wrap_transclusion transclusion
      "<div class=\"transclusion\">#{transclusion}</div>"
    end

  end

end
