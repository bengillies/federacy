class Tiddler < ActiveRecord::Base
  has_many :revisions, ->{ includes(:textable).order("created_at DESC") }, inverse_of: :tiddler, dependent: :destroy
  has_many :revision_tags, through: :latest_revision
  has_many :revision_fields, through: :latest_revision
  has_many :revision_links, through: :latest_revision
  has_many :all_revision_back_links, class_name: 'RevisionLink', dependent: :nullify
  has_one :latest_revision, -> {
    where(%q(revisions.id in (
      with latest_revisions as
        (select *, ROW_NUMBER() OVER (
          PARTITION BY tiddler_id ORDER BY created_at DESC
        ) as created_order from revisions
      ) select latest_revisions.id from latest_revisions where created_order = 1
    ))) }, class_name: "Revision"
  belongs_to :space, inverse_of: :tiddlers
  has_many :space_users, through: :space
  belongs_to :user
  has_many :file_revisions, inverse_of: :tiddler, dependent: :destroy
  has_many :text_revisions, inverse_of: :tiddler, dependent: :destroy

  validates_presence_of :space

  delegate :title, :text, :body, :content_type, :tags, :fields, :binary?, :modifier, :links, :linkable?, to: :current_revision

  scope :by_tag, ->(tag) {
    joins("inner join revision_tags on revisions.id = revision_tags.revision_id")
      .where(revision_tags: { name: tag })
      .uniq
  }
  scope :by_title, ->(title) { joins(:latest_revision).where(revisions: { title: title }) }
  scope :by_creator, ->(name) { joins(:user).where(users: { name: name }) }
  scope :by_modifier, ->(name) {
    joins(:latest_revision).joins('inner join users on revisions.user_id = users.id')
      .where(users: { name: name })
  }
  scope :by_content_type, ->(type) {
    joins(:latest_revision)
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
    joins(:latest_revision).where("revisions.created_at #{gte} ?", date)
  }
  scope :by_field, ->(field_hash) {
    scope = joins('inner join revision_fields on revisions.id = revision_fields.revision_id')
    field_hash.each do |name, value|
      scope = if value.nil?
        scope.where(revision_fields: { key: name })
      else
        scope.where(revision_fields: { key: name, value: value })
      end
    end
    scope
  }

  scope :visible_to_user, ->(user) {
    if user
      joins(:space_users).where(space_users: { user: user })
    else
      joins(:space).where(spaces: { space_type: Space.space_types[:open] })
    end
  }

  def creator
    user
  end

  def current_revision
    latest_revision || Revision.new
  end

  def created
    created_at
  end

  def modified
    current_revision.created_at
  end

  def back_links user
    visible_links = Tiddler
      .visible_to_user(user)
      .includes(:revision_links)
      .map(&:revision_links)
      .flatten
      .map(&:id)
    RevisionLink.where(tiddler: id, id: visible_links)
  end
end
