require_dependency 'links/resolver'

class ShortLinksController < ApplicationController
  respond_to :html, :json

  def show_space
    begin
      redirect_to link_resolver.resolve(params)
    rescue Links::SpaceNotFound
      not_found(:space)
    end
  end

  def show_tiddler
    begin
      redirect_to link_resolver.resolve(params)
    rescue Links::SpaceNotFound
      not_found(:space)
    rescue Links::TiddlerNotFound
      not_found(:tiddler)
    end
  end

  def show_space_tiddler
    begin
      redirect_to link_resolver.resolve(params)
    rescue Links::SpaceNotFound
      not_found(:space)
    rescue Links::TiddlerNotFound
      not_found(:tiddler)
    end
  end

  def show_user_space
    begin
      redirect_to link_resolver.resolve(params)
    rescue Links::SpaceNotFound
      not_found(:space)
    end
  end

  def show_user_space_tiddler
    begin
      redirect_to link_resolver.resolve(params)
    rescue Links::SpaceNotFound
      not_found(:space)
    rescue Links::TiddlerNotFound
      not_found(:tiddler)
    end
  end

  private

  def link_resolver
    Links::Resolver.new(root_url, current_user)
  end

end
