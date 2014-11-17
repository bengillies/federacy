require 'links/resolver'

class ShortLinksController < ApplicationController
  respond_to :html, :json

  def show_space
    begin
      redirect_to Links::Resolver.new(current_user).resolve(params)
    rescue Links::SpaceNotFound
      not_found(:space)
    end
  end

  def show_tiddler
    begin
      redirect_to Links::Resolver.new(current_user).resolve(params)
    rescue Links::SpaceNotFound
      not_found(:space)
    rescue Links::TiddlerNotFound
      not_found(:tiddler)
    end
  end

  def show_space_tiddler
    begin
      redirect_to Links::Resolver.new(current_user).resolve(params)
    rescue Links::SpaceNotFound
      not_found(:space)
    rescue Links::TiddlerNotFound
      not_found(:tiddler)
    end
  end

  def show_user_space
    begin
      redirect_to Links::Resolver.new(current_user).resolve(params)
    rescue Links::SpaceNotFound
      not_found(:space)
    end
  end

  def show_user_space_tiddler
    begin
      redirect_to Links::Resolver.new(current_user).resolve(params)
    rescue Links::SpaceNotFound
      not_found(:space)
    rescue Links::TiddlerNotFound
      not_found(:tiddler)
    end
  end

end
