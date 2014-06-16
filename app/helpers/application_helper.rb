module ApplicationHelper
  def markdown text
    renderer = Redcarpet::Markdown.new Redcarpet::Render::HTML.new
    renderer.render(text).html_safe
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

    render "shared/renderers/#{renderer}", object: tiddler
  end

  def html_path *args
    PathHelpers::html_path *args
  end

end
