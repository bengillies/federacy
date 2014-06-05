class Space < ActiveRecord::Base
  has_many :tiddlers, inverse_of: :space

  validates_presence_of :name
end
