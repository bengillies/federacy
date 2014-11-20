class BacklinksController < ApplicationController
  respond_to :json

  before_action :find_space, :find_tiddler

  def index
    @backlinks = @tiddler.back_links(current_user)
    respond_with @backlinks
  end

  private

  def find_space
    begin
      @space = Space.visible_to_user(current_user).find(params[:space_id])
    rescue ActiveRecord::RecordNotFound
      not_found "Space"
    end
  end

  def find_tiddler
    begin
      @tiddler = @space.tiddlers.find(params[:tiddler_id])
    rescue ActiveRecord::RecordNotFound
      not_found "Tiddler"
    end
  end
end

