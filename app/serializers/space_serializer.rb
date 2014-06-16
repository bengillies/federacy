class SpaceSerializer < ApplicationSerializer
  attributes :id, :name, :description, :render

  def render
    options[:scope].markdown object.description
  end
end
