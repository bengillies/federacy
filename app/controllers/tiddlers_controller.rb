class TiddlersController < ApplicationController
  respond_to :html, :json

  before_action :find_space

  self.responder = TiddlerResponder

  def index
    @tiddlers = @space.tiddlers.all
    respond_with @tiddlers
  end

  def show
    @tiddler = @space.tiddlers.find(params[:id])
    respond_with @tiddler
  end

  def new
    @tiddler = @space.tiddlers.build
  end

  def edit
    @tiddler = @space.tiddlers.find(params[:id])
  end

  def create
    @tiddler = @space.tiddlers.build
    @tiddler.new_revision tiddler_params

    if @tiddler.save
      redirect_to space_tiddler_path id: @tiddler, format: :html
    else
      redirect_to new_space_tiddler_path
    end
  end

  def update
    @tiddler = @space.tiddlers.find(params[:id])
    @tiddler.new_revision tiddler_params

    if @tiddler.save
      redirect_to space_tiddler_path format: :html
    else
      redirect_to edit_space_tiddler_path
    end
  end

  def destroy
    @tiddler = @space.tiddlers.find(params[:id])

    if @tiddler.destroy
      redirect_to space_tiddlers_path
    else
      redirect_to edit_space_tiddler_path
    end
  end

  private

  def find_space
    @space = Space.find(params[:space_id])
  end

  def tiddler_params
    params.require(:tiddler).permit(:title, :text, :file, :tags, :fields, :content_type)
  end
end
