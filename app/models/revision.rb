class Revision < ActiveRecord::Base
  has_many :revision_fields, inverse_of: :revision, dependent: :delete_all
  has_many :revision_tags, inverse_of: :revision, dependent: :delete_all
  has_many :revision_links, inverse_of: :revision, dependent: :delete_all
  has_many :back_links, class_name: 'RevisionLink', inverse_of: :tiddler, foreign_key: :tiddler_id, dependent: :nullify
  belongs_to :tiddler, inverse_of: :revisions
  belongs_to :textable, polymorphic: true
  belongs_to :user

  before_save :set_defaults

  scope :by_tag, ->(tag) { joins(:revision_tags).where(revision_tags: { name: tag }) }
  scope :by_title, ->(title) { where(title: title) }
  scope :by_creator, ->(name) { joins(:user).where(users: { name: name }) }
  scope :by_modifier, ->(name) {
    by_creator(name)
  }
  scope :by_content_type, ->(type) {
    joins('left outer join text_revisions on revisions.textable_id = text_revisions.id')
      .joins('left outer join file_revisions on revisions.textable_id = file_revisions.id')
      .where("(revisions.textable_type = 'TextRevision' AND text_revisions.content_type = ?) \
        OR (revisions.textable_type = 'FileRevision' AND file_revisions.content_type = ?)",
        type, type)
  }
  scope :by_created, ->(date) {
    gte = date.start_with?('>') ? '>=' : date.start_with?('<') ? '<=' : '='
    date = date.gsub(/^<|>/, '') unless gte == '='
    where("revisions.created_at #{gte} ?", date)
  }
  scope :by_modified, ->(date) {
    by_created(date)
  }
  scope :by_field, ->(field_hash) {
    scope = joins(:revision_fields)
    field_hash.each do |name, value|
      scope = if value.nil?
        scope.where(revision_fields: { key: name })
      else
        scope.where(revision_fields: { key: name, value: value })
      end
    end
    scope
  }

  def modifier
    user
  end

  def created
    created_at
  end

  def body
    if textable.respond_to? :body then textable.body else nil end
  end

  def text
    tiddler_text = if textable.respond_to? :text then textable.text else nil end
    tiddler_text || ''
  end

  def content_type
    if textable.respond_to? :content_type then textable.content_type else nil end
  end

  def tags
    @tags ||= TagList.new revision_tags
  end

  def fields
    @fields ||= Hash[revision_fields.pluck(:key, :value)]
  end

  def add_tags new_tags
    unless new_tags.respond_to? :each
      new_tags = TagList.from_s new_tags
    end

    new_tags.each {|name| revision_tags.build name: name }
    new_tags
  end

  def add_fields new_fields
    new_fields.each {|k, v| revision_fields.build key: k, value: v }
    new_fields
  end

  def links
    revision_links
  end

  def binary?
    textable_type == "FileRevision"
  end

  def read_only?
    new_record? ? false : true
  end

  protected

  def set_defaults
    self.tiddler_id ||= textable.tiddler_id
  end
end
