class RevisionLink < ActiveRecord::Base
  belongs_to :revision
  belongs_to :space
  belongs_to :user
  belongs_to :tiddler, class_name: 'Revision'

  enum link_type: [
    :tiddlylink,
    :tiddlyimage,
    :transclusion,
    :markdown_link,
    :markdown_image
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
    tiddler.tiddler
  end

end
