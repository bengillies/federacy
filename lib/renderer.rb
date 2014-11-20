require_dependency 'links/transcluder'
require_dependency 'markdown/renderer'

class Renderer
  attr_reader :space

  def initialize opts
    @current_user = opts[:user]
    @space = opts[:space]
    @view = opts[:view]
    @root_url = opts[:root_url]
    @tokens = opts[:tokens] || {
      start: SecureRandom.uuid + '_START',
      end: SecureRandom.uuid + '_END'
    }
    @transcluder = opts[:transcluder] || Links::Transcluder.new(@root_url, self, opts[:user])
  end

  def clone space=nil, transcluder=nil
    @transcluder.space = space if space
    Renderer.new(
      view: @view,
      user: @current_user,
      space: space || @space,
      transcluder: transcluder,
      tokens: @tokens,
      root_url: @root_url
    )
  end

  def markdown_html tiddler=nil
    @markdown_html ||= Markdown::Renderer.new(
      space: @space,
      tokens: @tokens,
      tiddler: tiddler,
      with_toc_data: true
    )
  end

  def markdown_renderer space, tiddler=nil
    @markdown_renderer ||= Redcarpet::Markdown.new(
      markdown_html(tiddler),
      :no_intra_emphasis => true,
      :tables => true,
      :fenced_code_blocks => true,
      :autolink => true,
      :strikethrough => true,
      :superscript => true,
      :highlight => true,
      :quotes => true
    )
  end

  def markdown text, tiddler=nil
    text = markdown_renderer(@space, tiddler).render(text)
    @transcluder.transclude(text, @markdown_html.transclusions, @tokens).html_safe
  end

  def render_tiddler tiddler, options
    content_type = options[:content_type]

    types = {
      /^text\/x-markdown/ => :markdown,
      /^text\/plain/ => :text,
      /^image\// => :image
    }

    mime_type = types.find {|regex, val| regex.match content_type }
    render_type = if mime_type
      mime_type.last
    else
      if tiddler.binary?
        :binary
      else
        :text
      end
    end

    if @transcluder.transcluding? && render_type == :markdown
      markdown(tiddler.text, tiddler)
    else
      @view.render "shared/renderers/#{render_type}.html.erb", object: tiddler
    end
  end

end
