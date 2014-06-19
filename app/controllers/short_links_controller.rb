class ShortLinksController < ApplicationController
  respond_to :html, :json

  def show_space
    @space = Space.visible_to_user(current_user).find_by_name params[:space_name]
    return not_found(:space) if @space.nil?
    redirect_to @space
  end

  def show_tiddler
    @space = Space.visible_to_user(current_user).find(params[:space_id])
    return not_found(:space) if @space.nil?
    @tiddler = @space.tiddlers.by_title(params[:tiddler_title]).first
    return not_found(:tiddler) if @tiddler.nil?
    redirect_to [@space, @tiddler]
  end

  def show_space_tiddler
    @space = Space.visible_to_user(current_user).find_by_name params[:space_name]
    return not_found(:space) if @space.nil?
    @tiddler = @space.tiddlers.by_title(params[:tiddler_title]).first
    return not_found(:tiddler) if @tiddler.nil?
    redirect_to [@space, @tiddler]
  end

  def show_user_space
    @space = User.find_by_name(params[:username]).spaces.visible_to_user(current_user).find_by_name params[:space_name]
    return not_found(:space) if @space.nil?
    redirect_to @space
  end

  def show_user_space_tiddler
    @space = User.find_by_name(params[:username]).spaces.visible_to_user(current_user).find_by_name params[:space_name]
    return not_found(:space) if @space.nil?
    @tiddler = @space.tiddlers.by_title(params[:tiddler_title]).first
    return not_found(:tiddler) if @tiddler.nil?
    redirect_to [@space, @tiddler]
  end

end
