class SpaceUserSerializer < ApplicationSerializer
  attributes :id, :access, :user, :space

  def user
    { id: object.user.id, name: object.user.name, icon: object.user.icon.url }
  end

  def space
    { id: object.space.id, name: object.space.name }
  end
end
