class Tiddler < ActiveRecord::Base
  has_many :revisions, ->{ order "created_at DESC" }, inverse_of: :tiddler
  belongs_to :space, inverse_of: :tiddlers

  validates_presence_of :space

  %w(title text content_type tags fields).each do |k|
    define_method k do
      current_revision.send k
    end
  end

  def current_revision
    revisions.first
  end

  def created
    created_at
  end

  def modified
    current_revision.created_at
  end

  def new_revision attrs
    revision = {
      fields: Hash[fields.pluck(:key, :value)],
      tags: tags.map(&:name),
      title: title,
      text: text,
      content_type: content_type,
    }.merge(attrs)

    new_fields = revision[:fields]
    new_tags = revision[:tags]

    revision.delete :tags
    revision.delete :fields

    revision = revisions.build revision

    revision.add_tags new_tags
    revision.add_fields new_fields

    revision
  end
end
