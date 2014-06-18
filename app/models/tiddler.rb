class Tiddler < ActiveRecord::Base
  has_many :revisions, ->{ order "created_at DESC" }, inverse_of: :tiddler, dependent: :destroy
  has_many :revision_tags, through: :revisions
  has_many :revision_fields, through: :revisions
  belongs_to :space, inverse_of: :tiddlers
  belongs_to :user
  has_many :file_revisions, inverse_of: :tiddler, dependent: :destroy
  has_many :text_revisions, inverse_of: :tiddler, dependent: :destroy

  validates_presence_of :space

  delegate :title, :text, :body, :content_type, :tags, :fields, :binary?, :modifier, to: :current_revision

  scope :by_tag, ->(tag) { joins(:revisions, :revision_tags).where(revision_tags: { name: tag }) }
  scope :by_title, ->(title) { joins(:revisions).where(revisions: { title: title }) }
  scope :by_creator, ->(name) { joins(:user).where(users: { name: name }) }
  scope :by_modifier, ->(name) {
    joins(:revisions).joins('inner join users on revisions.user_id = users.id')
      .where(users: { name: name })
  }
  scope :by_content_type, ->(type) {
    joins(:revisions)
      .joins('left outer join text_revisions on revisions.textable_id = text_revisions.id')
      .joins('left outer join file_revisions on revisions.textable_id = file_revisions.id')
      .where("(revisions.textable_type = 'TextRevision' AND text_revisions.content_type = ?) \
        OR (revisions.textable_type = 'FileRevision' AND file_revisions.content_type = ?)",
        type, type)
  }
  scope :by_created, ->(date) {
    gte = date.start_with?('>') ? '>=' : date.start_with?('<') ? '<=' : '='
    date = date.gsub(/^<|>/, '') unless gte == '='
    where("tiddlers.created_at #{gte} ?", date)
  }
  scope :by_modified, ->(date) {
    gte = date.start_with?('>') ? '>=' : date.start_with?('<') ? '<=' : '='
    date = date.gsub(/^<|>/, '') unless gte == '='
    joins(:revisions).where("revisions.created_at #{gte} ?", date)
  }
  scope :by_field, ->(field_hash) {
    scope = joins(:revisions, :revision_fields)
    field_hash.each do |name, value|
      scope = if value.nil?
        scope.where(revision_fields: { key: name })
      else
        scope.where(revision_fields: { key: name, value: value })
      end
    end
    scope
  }

  def creator
    user
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
    revision_body = revision_type(attrs).build
    revision_body.set_body! attrs

    revision = revision_body.revisions.build title: attrs["title"], user_id: attrs["current_user"].id
    revision.add_tags attrs["tags"] unless attrs.fetch("tags", nil).nil?
    revision.add_fields attrs["fields"] unless attrs.fetch("fields", nil).nil?

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
