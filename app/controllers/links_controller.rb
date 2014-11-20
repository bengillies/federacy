class LinksController < ApplicationController
  respond_to :json

  before_action :find_space, :find_tiddler, :find_revision

  def index
    @links = (@revision || @tiddler).links
    respond_with @links
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

  def find_revision
    return unless params.has_key? :revision_id
    begin
      @revision = @tiddler.revisions.find(params[:revision_id])
    rescue ActiveRecord::RecordNotFound
      not_found "Revision"
    end
  end
end
