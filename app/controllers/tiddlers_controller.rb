class TiddlersController < ApplicationController
  respond_to :html, :json

  def index
    @tiddlers = Space.find(params[:space_id]).tiddlers.all
    respond_with @tiddlers
  end

  def show
    @tiddler = Space.find(params[:space_id]).tiddlers.find(params[:id])
    respond_with @tiddler
  end

  def new
    @tiddler = Space.find(params[:space_id]).tiddlers.build
  end

  def edit
    @tiddler = Space.find(params[:space_id]).tiddlers.find(params[:id])
  end

  def create
    @tiddler = Space.find(params[:space_id]).tiddlers.build
    @tiddler.new_revision tiddler_params

    if @tiddler.save
      redirect_to space_tiddler_path id: @tiddler
    else
      flash[:error] = "There was a problem creating the tiddler"
      redirect_to new_space_tiddler_path
    end
  end

  def update
    @tiddler = Space.find(params[:space_id]).tiddlers.find(params[:id])
    @tiddler.new_revision tiddler_params

    if @tiddler.save
      redirect_to space_tiddler_path
    else
      flash[:error] = "There was a problem saving the tiddler"
      redirect_to edit_space_tiddler_path
    end
  end

  def destroy
    @tiddler = Space.find(params[:space_id]).tiddlers.find(params[:id])

    if @tiddler.destroy
      redirect_to space_tiddlers_path
    else
      flash[:error] = "There was a problem deleting the tiddler"
      redirect_to edit_space_tiddler_path
    end
  end

  private

  def tiddler_params
    params.require(:tiddler).permit(:title, :text, :tags, :fields, :content_type)
  end
end
