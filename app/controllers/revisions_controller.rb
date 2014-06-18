class RevisionsController < ApplicationController
  include Filterable

  respond_to :html, :json

  before_action :authenticate_user!, only: [:create]
  before_action :find_space, :find_tiddler

  self.responder = TiddlerResponder

  def index
    @revisions = apply_scopes(@tiddler.revisions).all
    respond_with @revisions do |format|
      format.atom { render layout: false }
    end
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
      return forbidden(:revert, :tiddler) unless edit_tiddler?
    rescue ActiveRecord::RecordNotFound
      return unprocessable_entity
    end
    @tiddler.new_revision_from_previous @revision.id, "current_user" => current_user

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
