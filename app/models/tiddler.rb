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
    default_params = {
      "fields" => fields,
      "tags" => tags.map(&:name),
      "title" => title,
      "text" => text,
      "content_type" => content_type,
    }

    revision = default_params.merge(attrs)

    new_fields = revision["fields"]
    new_tags = revision["tags"]

    revision.delete "tags"
    revision.delete "fields"

    Rails.logger.info "revision is: #{revision.inspect}"

    revision = revisions.build revision

    revision.add_tags(new_tags) if new_tags
    revision.add_fields(new_fields) if new_fields

    revision
  end
end
