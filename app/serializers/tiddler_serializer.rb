class TiddlerSerializer < ActiveModel::Serializer
  attributes :id, :title, :text, :tags, :fields, :created, :modified, :content_type, :space

  def space
    { id: object.space.id, name: object.space.name }
  end

  def tags
    object.tags.map(&:to_s)
  end
end
