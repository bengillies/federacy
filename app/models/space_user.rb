class SpaceUser < ActiveRecord::Base
  belongs_to :space
  belongs_to :user

  enum access: [:full, :read_only, :owned_only, :admin]

  def self.access_descriptions
    self.accesses.map {|k, v| [k.gsub('_', ' '), k]}
  end
end
