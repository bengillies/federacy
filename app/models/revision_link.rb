class RevisionLink < ActiveRecord::Base
  belongs_to :revision
  belongs_to :space
  belongs_to :user
  belongs_to :tiddler
  belongs_to :target, class_name: 'Revision'

  before_save :set_defaults

  enum link_type: [
    :tiddlylink,
    :tiddlyimage,
    :transclusion,
    :markdown_link,
    :markdown_image,
    :inline_link
  ]

  validates_presence_of :title, :start, :end, :link_type


  scope :tiddly_style_links, -> {
    where(link_type: [
      link_types[:tiddlylink],
      link_types[:tiddlyimage],
      link_types[:transclusion]
    ])
  }

  def from
    revision.tiddler
  end

  def to
    tiddler
  end

  protected

  def set_defaults
    self.tiddler_id = target.tiddler_id if target
  end

end
