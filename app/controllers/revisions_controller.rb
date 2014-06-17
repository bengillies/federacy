class RevisionsController < ApplicationController
  respond_to :html, :json

  before_action :find_space, :find_tiddler

  self.responder = TiddlerResponder

  def index
    @revisions = @tiddler.revisions.all
    respond_with @revisions
  end

  def show
    begin
      @revision = @tiddler.revisions.find(params[:id])
      respond_with @revision
    rescue ActiveRecord::RecordNotFound
      not_found "Revision"
    end
  end

  def create
    begin
    @revision = @tiddler.revisions.find params[:revision][:id]
    rescue ActiveRecord::RecordNotFound
      return unprocessable_entity
    end
    @tiddler.new_revision_from_previous @revision.id

    respond_with do |format|
      if @tiddler.save
        format.html {
          redirect_to PathHelpers::html_path :space_tiddler_path, @space, @tiddler
        }
        format.json {
          created :json, @tiddler, space_tiddler_path(@space, @tiddler)
        }
      else
        format.html {
          redirect_to PathHelpers::html_path :space_tiddler_revision_path,
            @space, @tiddler, @revision
        }
        format.json { unprocessable_entity }
      end
    end
  end

  private

  def find_space
    begin
      @space = Space.find(params[:space_id])
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
