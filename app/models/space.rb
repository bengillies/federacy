class Space < ActiveRecord::Base
  has_many :tiddlers, ->{
    select("tiddlers.*, max(revisions.updated_at) as last_updated_at")
      .joins(:revisions)
      .group("tiddlers.id")
      .order("last_updated_at DESC")
  }, inverse_of: :space, dependent: :destroy

  validates_presence_of :name

  def to_s
    name
  end
end
