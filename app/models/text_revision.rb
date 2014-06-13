class TextRevision < ActiveRecord::Base
  has_many :revisions, as: :textable
  belongs_to :tiddler, inverse_of: :text_revisions
end
