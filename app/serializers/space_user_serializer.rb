class SpaceUserSerializer < ApplicationSerializer
  attributes :id, :access, :user, :space

  def user
    { id: object.user.id, email: object.user.email }
  end

  def space
    { id: object.space.id, name: object.space.name }
  end
end
