class ApplicationSerializer < ActiveModel::Serializer
  def include_render?
    options[:scope].params[:render]
  end

  def render
    options[:scope].render_tiddler object, content_type: object.content_type
  end
end
