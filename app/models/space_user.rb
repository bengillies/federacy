class SpaceUser < ActiveRecord::Base
  belongs_to :space
  belongs_to :user

  enum access: [:full, :read_only, :owned_only, :admin]
end
