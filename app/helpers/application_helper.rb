module ApplicationHelper
  def markdown text
    renderer = Redcarpet::Markdown.new Redcarpet::Render::HTML.new
    renderer.render(text).html_safe
  end

  def render_tiddler tiddler, options
    content_type = options[:content_type]

    mime_type = Mime::Type.lookup(content_type) || Mime[:text]

    render "shared/renderers/#{mime_type.symbol}", object: tiddler
  end
end
