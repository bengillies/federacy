require_dependency 'renderer'

module ApplicationHelper

  def renderer
    Renderer.new(
      view: self,
      user: @current_user,
      space: @space
    )
  end

  def markdown text, tiddler=nil
    renderer.markdown text, tiddler
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
