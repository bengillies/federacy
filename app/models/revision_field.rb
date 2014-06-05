class RevisionField < ActiveRecord::Base
  belongs_to :revision, inverse_of: :revision_fields

  validates_presence_of :revision, :key

  def read_only?
    new_record? ? false : true
  end
end
