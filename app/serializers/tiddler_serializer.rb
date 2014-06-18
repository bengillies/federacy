class TiddlerSerializer < ApplicationSerializer
  attributes :id, :title, :text, :tags, :fields, :created, :modified,
    :content_type, :space, :render, :creator, :modifier

  def space
    { id: object.space.id, name: object.space.name }
  end

  def creator
    { id: object.creator.id, name: object.creator.name, icon: object.creator.icon.url }
  end

  def modifier
    { id: object.modifier.id, email: object.modifier.name, icon: object.modifier.icon.url }
  end

  def tags
    object.tags.map(&:to_s)
  end
end
