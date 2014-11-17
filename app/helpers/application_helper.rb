require 'renderer'

module ApplicationHelper

  def renderer
    Renderer.new self, @current_user, @space
  end

  def markdown text
    renderer.markdown text
  end

  def render_tiddler tiddler, options
    renderer.render_tiddler tiddler, options
  end

  def html_path *args
    PathHelpers::html_path *args
  end

  def user_can?(action, object)
    current_user && current_user.send("#{action}?", object)
  end

end
