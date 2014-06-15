class TextRevision < ActiveRecord::Base
  has_many :revisions, as: :textable
  belongs_to :tiddler, inverse_of: :text_revisions

  before_save :set_defaults

  validates_presence_of :tiddler

  def body
    text
  end

  def set_body! attrs
    self.text = attrs.fetch("text", nil)
    self.content_type = attrs.fetch('content_type', nil)
  end

  protected

  def set_defaults
    self.content_type = 'text/x-markdown' if content_type.blank?
  end
end
