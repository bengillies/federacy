class RevisionsController < ApplicationController
  respond_to :html, :json

  before_action :find_space, :find_tiddler

  def index
    @revisions = @tiddler.revisions.all
    respond_with @revisions
  end

  def show
    @revision = @tiddler.revisions.find(params[:id])
    respond_with @revision
  end

  private

  def find_space
    @space = Space.find(params[:space_id])
  end

  def find_tiddler
    @tiddler = @space.tiddlers.find(params[:tiddler_id])
  end
end
