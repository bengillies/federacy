class RevisionSerializer < ActiveModel::Serializer
  attributes :id, :title, :text, :tags, :fields, :created, :content_type,
    :space, :tiddler

  def space
    { id: object.tiddler.space.id, name: object.tiddler.space.name }
  end

  def tags
    object.tags.map(&:to_s)
  end

  def tiddler
    { id: object.tiddler.id, title: object.tiddler.title }
  end
end
