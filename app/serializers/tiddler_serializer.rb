class TiddlerSerializer < ApplicationSerializer
  attributes :id, :title, :text, :tags, :fields, :created, :modified,
    :content_type, :space, :render, :creator, :modifier

  def space
    { id: object.space.id, name: object.space.name }
  end

  def creator
    { id: object.creator.id, email: object.creator.email }
  end

  def modifier
    { id: object.modifier.id, email: object.modifier.email }
  end

  def tags
    object.tags.map(&:to_s)
  end
end
