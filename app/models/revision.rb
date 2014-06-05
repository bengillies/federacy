class Revision < ActiveRecord::Base
  has_many :revision_fields, inverse_of: :revision
  has_many :revision_tags, inverse_of: :revision
  belongs_to :tiddler, inverse_of: :revisions

  validates_presence_of :title, :tiddler, :content_type

  alias_method :tags, :revision_tags
  alias_method :fields, :revision_fields

  def read_only?
    new_record? ? false : true
  end

  def add_tags new_tags
    new_tags.each {|name| tags.build name: name }
    new_tags
  end

  def add_fields new_fields
    new_fields.each {|k, v| fields.build key: k, value: v }
    new_fields
  end
end
