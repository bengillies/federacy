class RevisionSerializer < ApplicationSerializer
  attributes :id, :title, :text, :tags, :fields, :created, :content_type,
    :space, :tiddler, :render, :modifier

  def space
    { id: object.tiddler.space.id, name: object.tiddler.space.name }
  end

  def modifier
    { id: object.modifier.id, name: object.modifier.name, icon: object.modifier.icon.url }
  end

  def tags
    object.tags.map(&:to_s)
  end

  def tiddler
    { id: object.tiddler.id, title: object.tiddler.title }
  end
end

