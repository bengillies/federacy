class RevisionTag < ActiveRecord::Base
  belongs_to :revision, inverse_of: :revision_tags

  validates_presence_of :revision, :name

  def read_only?
    new_record? ? false : true
  end

  def to_s
    name
  end
end
