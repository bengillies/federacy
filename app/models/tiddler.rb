class Tiddler < ActiveRecord::Base
  has_many :revisions, ->{ order "created_at DESC" }, inverse_of: :tiddler, dependent: :destroy
  belongs_to :space, inverse_of: :tiddlers
  has_many :file_revisions, inverse_of: :tiddler, dependent: :destroy
  has_many :text_revisions, inverse_of: :tiddler, dependent: :destroy

  validates_presence_of :space

  delegate :title, :text, :content_type, :tags, :fields, :binary?, to: :current_revision

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
    revision_body = revision_type(attrs).build
    revision_body.set_body! attrs

    revision = revision_body.revisions.build title: attrs["title"]
    revision.add_tags attrs["tags"] if attrs.has_key? "tags"
    revision.add_fields attrs["fields"] if attrs.has_key? "fields"

    revision
  end

  def new_revision_from_previous previous_revision_id, attrs = {}
    revision = revisions.find previous_revision_id

    new_attrs = {
      "title" => revision.title,
      "tags" => revision.tags.to_s,
      "fields" => revision.fields,
      "content_type" => revision.content_type,
    }.merge(attrs)

    if revision.binary?
      new_attrs["file"] ||= revision.body
    else
      new_attrs["text"] ||= revision.body
    end

    new_revision new_attrs
  end

  private

  def revision_type attrs
    if attrs.has_key?("file") then file_revisions else text_revisions end
  end
end
