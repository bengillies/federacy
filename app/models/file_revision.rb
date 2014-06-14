class FileRevision < ActiveRecord::Base
  has_many :revisions, as: :textable
  belongs_to :tiddler, inverse_of: :file_revisions

  before_save :set_defaults

  validates_presence_of :tiddler

  mount_uploader :file, BinaryTiddlerUploader

  def text
    file.url
  end

  def set_body! attrs
    self.file = attrs["file"]
    self.content_type = attrs["content_type"]
  end

  protected

  def set_defaults
    self.content_type = file.content_type unless file.content_type.blank?
  end
end
