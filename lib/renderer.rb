require 'links/transcluder'
require 'markdown/renderer'

class Renderer

  def initialize view, user, space, transcluder=nil
    @current_user = user
    @space = space
    @view = view
    @transcluder = transcluder || Links::Transcluder.new(self, user, space)
  end

  def clone space=nil, transcluder=nil
    @transcluder.space = space if space
    Renderer.new(@view, @current_user, space || @space, transcluder)
  end

  def markdown_html
    @markdown_html ||= Markdown::Renderer.new(space: @space, with_toc_data: true)
  end

  def markdown_renderer space
    @markdown_renderer ||= Redcarpet::Markdown.new(
      markdown_html,
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

  def markdown text
    text = markdown_renderer(@space).render(text)
    @transcluder.transclude(text, @markdown_html.transclusion).html_safe
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
      markdown(tiddler.text)
    else
      @view.render "shared/renderers/#{render_type}.html.erb", object: tiddler
    end
  end

end