class FileRevision < ActiveRecord::Base
  has_many :revisions, as: :textable
  belongs_to :tiddler, inverse_of: :file_revisions

  def text
    file_path
  end
end
