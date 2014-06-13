class Tiddler < ActiveRecord::Base
  has_many :revisions, ->{ order "created_at DESC" }, inverse_of: :tiddler, dependent: :destroy
  belongs_to :space, inverse_of: :tiddlers

  validates_presence_of :space

  %w(title text content_type tags fields).each do |k|
    define_method k do
      current_revision.send k
    end
  end

  def current_revision
    revisions.first || Revision.new
  end

  def created
    created_at
  end

  def modified
    current_revision.created_at
  end

  def new_revision attrs
    revision = revisions.build attrs.except "tags", "fields"
    revision.add_tags attrs["tags"] if attrs.has_key? "tags"
    revision.add_fields attrs["fields"] if attrs.has_key? "fields"
    revision
  end
end
