require_dependency 'links/resolver'

class ShortLinksController < ApplicationController
  respond_to :html, :json

  def show_space
    begin
      redirect_to link_resolver.resolve(params)
    rescue Links::SpaceNotFound
      new_space
    end
  end

  def show_tiddler
    begin
      redirect_to link_resolver.resolve(params)
    rescue Links::SpaceNotFound
      new_space
    rescue Links::TiddlerNotFound
      new_tiddler
    end
  end

  def show_space_tiddler
    begin
      redirect_to link_resolver.resolve(params)
    rescue Links::SpaceNotFound
      new_space
    rescue Links::TiddlerNotFound
      new_tiddler
    end
  end

  def show_user_space
    begin
      redirect_to link_resolver.resolve(params)
    rescue Links::SpaceNotFound
      new_space
    end
  end

  def show_user_space_tiddler
    begin
      redirect_to link_resolver.resolve(params)
    rescue Links::SpaceNotFound
      new_space
    rescue Links::TiddlerNotFound
      new_tiddler
    end
  end

  private

  def link_resolver
    @link_resolver ||= Links::Resolver.new(root_url: root_url, user: current_user)
  end

  def new_space
    respond_with do |t|
      t.json { not_found(:space) }
      t.html do
        redirect_to new_space_path(name: params[:space_name]), status: 303
      end
    end
  end

  def new_tiddler
    respond_with do |t|
      t.json { not_found(:tiddler) }
      t.html do
        redirect_to(
          new_space_tiddler_path(
            @link_resolver.found_space, title: params[:tiddler_title]),
          status: 303
        )
      end
    end
  end

end
