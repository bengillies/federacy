class RevisionsController < ApplicationController
  respond_to :html, :json

  def index
    @revisions = Space.find(params[:space_id]).tiddlers.find(params[:tiddler_id]).revisions.all
    respond_with @revisions
  end

  def show
    @revision = Space.find(params[:space_id]).tiddlers.find(params[:tiddler_id]).revisions.find(params[:id])
    respond_with @revision
  end
end
