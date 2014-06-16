class RevisionsController < ApplicationController
  respond_to :html, :json

  before_action :find_space, :find_tiddler

  self.responder = TiddlerResponder

  def index
    @revisions = @tiddler.revisions.all
    respond_with @revisions
  end

  def show
    @revision = @tiddler.revisions.find(params[:id])
    respond_with @revision
  end

  def create
    @tiddler.new_revision_from_previous params[:revision][:id]

    if @tiddler.save
      redirect_to space_tiddler_path id: @tiddler.id, format: :html
    else
      redirect_to space_tiddler_revision_path tiddler_id: @tiddler.id,
        id: params[:revision][:id], format: :html
    end
  end

  private

  def find_space
    @space = Space.find(params[:space_id])
  end

  def find_tiddler
    @tiddler = @space.tiddlers.find(params[:tiddler_id])
  end
end
