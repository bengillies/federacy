class SpacesController < ApplicationController
  respond_to :html, :json

  wrap_parameters :space, include: %w(name description)

  before_action :authenticate_user!, only: [:new, :edit, :create, :update, :destroy]

  def index
    @spaces = Space.visible_to_user(current_user)

    respond_with @spaces do |format|
      format.atom { render layout: false }
    end
  end

  def show
    begin
      @space = Space.visible_to_user(current_user).find(params[:id])
      respond_with @space
    rescue ActiveRecord::RecordNotFound
      not_found "Space"
    end
  end

  def new
    @space = Space.new
  end

  def edit
    begin
      @space = Space.find params[:id]
      return forbidden(:edit, :space) unless edit_space?
      @space
    rescue ActiveRecord::RecordNotFound
      not_found "Space"
    end
  end

  def update
    begin
      @space = Space.find params[:id]
      return forbidden(:edit, :space) unless edit_space?
      @space
    rescue ActiveRecord::RecordNotFound
      return not_found "Space"
    end

    @space.update space_params

    respond_with do |format|
      if @space.save
        format.html { redirect_to @space }
        format.json { no_content }
      else
        format.html { redirect_to edit_space_path }
        format.json { unprocessable_entity }
      end
    end
  end

  def create
    @space = Space.new_with_user space_params

    respond_with do |format|
      if @space.save
        format.html { redirect_to @space }
        format.json { created :json, @space, space_path(@space) }
      else
        format.html { redirect_to new_space_path }
        format.json { unprocessable_entity }
      end
    end
  end

  def destroy
    begin
      @space = Space.find params[:id]
      return forbidden(:delete, :space) unless delete_space?
      @space
    rescue ActiveRecord::RecordNotFound
      return not_found "Space"
    end

    respond_with do |format|
      if @space.destroy
        format.html { redirect_to spaces_path }
        format.json { no_content }
      else
        format.html { redirect_to edit_space_path }
        format.json { unprocessable_entity }
      end
    end
  end

  private

  def space_params
    params.require(:space).permit(:name, :description, :space_type)
  end
end
