class SpacesController < ApplicationController
  respond_to :html, :json

  def index
    @spaces = Space.all
    respond_with @spaces
  end

  def show
    @space = Space.find params[:id]
    respond_with @space
  end

  def new
    @space = Space.new
  end

  def edit
    @space = Space.find params[:id]
  end

  def update
    @space = Space.find params[:id]

    @space.update space_params

    if @space.save
      redirect_to @space
    else
      redirect_to edit_space_path
    end
  end

  def create
    @space = Space.new space_params

    if @space.save
      redirect_to @space
    else
      redirect_to new_space_path
    end
  end

  def destroy
    @space = Space.find params[:id]

    if @space.destroy
      redirect_to spaces_path
    else
      redirect_to edit_space_path
    end
  end

  private

  def space_params
    params.require(:space).permit(:name, :description)
  end

end
