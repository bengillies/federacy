require 'markdown/renderer'

module ApplicationHelper

  def markdown_renderer space
    Redcarpet::Markdown.new(
      Markdown::Renderer.new(space: space),
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
    markdown_renderer(@space).render(text).html_safe
  end

  def render_tiddler tiddler, options
    content_type = options[:content_type]

    types = {
      /^text\/x-markdown/ => :markdown,
      /^text\/plain/ => :text,
      /^image\// => :image
    }

    mime_type = types.find {|regex, val| regex.match content_type }
    renderer = if mime_type
      mime_type.last
    else
      if tiddler.binary?
        :binary
      else
        :text
      end
    end

    render "shared/renderers/#{renderer}.html.erb", object: tiddler
  end

  def html_path *args
    PathHelpers::html_path *args
  end

  def user_can?(action, object)
    current_user && current_user.send("#{action}?", object)
  end

end
