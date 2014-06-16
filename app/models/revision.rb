class Revision < ActiveRecord::Base
  has_many :revision_fields, inverse_of: :revision, dependent: :delete_all
  has_many :revision_tags, inverse_of: :revision, dependent: :delete_all
  belongs_to :tiddler, inverse_of: :revisions
  belongs_to :textable, polymorphic: true

  before_save :set_defaults

  def created
    created_at
  end

  def body
      if textable.respond_to? :body then textable.body else nil end
  end

  def text
    if textable.respond_to? :text then textable.text else nil end
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
