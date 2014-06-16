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
    @revision = @tiddler.revisions.find params[:revision][:id]
    @tiddler.new_revision_from_previous @revision.id

    if @tiddler.save
      redirect_to PathHelpers::html_path :space_tiddler_path, @space, @tiddler
    else
      redirect_to PathHelpers::html_path :space_tiddler_revision_path,
        @space, @tiddler, @revision
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
