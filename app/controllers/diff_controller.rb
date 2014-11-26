require_dependency 'links/resolver'

class DiffController < ApplicationController

  respond_to :html, :json

  before_action :find_space, :find_tiddler, only: :revision_diff

  def revision_diff
    old_revision = @tiddler.revisions.find(diff_params[:old])
    new_revision = @tiddler.revisions.find(diff_params[:new])
    @diff = Diff.new :tiddler, old_revision, new_revision

    respond_with @diff
  end

  def generic_diff
    type, old, new = find_from_url
    @diff = Diff.new(type, old, new)
    respond_with @diff, template: "diff/generic/#{type}.html.erb"
  end

  private

  def diff_params
    params.require(:old)
    params.require(:new)
    params
  end

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

  # find the requested tiddlers/spaces for diffing
  def find_from_url
    resolver = Links::Resolver.new(root_url: root_url, user: current_user)
    old = resolver.extract_link_info(link: diff_params[:old])
    new = resolver.extract_link_info(link: diff_params[:new])
    type = :tiddler

    if old[:tiddler_id] && new[:tiddler_id]
      tiddler_old = Space.visible_to_user(current_user)
        .find(old[:space_id]).tiddlers.find(old[:tiddler_id])
      tiddler_new = Space.visible_to_user(current_user)
        .find(new[:space_id]).tiddlers.find(new[:tiddler_id])
      if old[:target_id]
        old = tiddler_old.revisions.find(old[:target_id])
      else
        old = tiddler_old.current_revision
      end
      if new[:target_id]
        new = tiddler_new.revisions.find(new[:target_id])
      else
        new = tiddler_new.current_revision
      end
    elsif old[:tiddler_id] || new[:tiddler_id]
      raise ActionController::BadRequest.new("Only one of the urls given was a tiddler")
    elsif old[:space_id] && new[:space_id]
      type = :space
      old = Space.visible_to_user(current_user).find(old[:space_id])
      new = Space.visible_to_user(current_user).find(new[:space_id])
    else
      raise ActionController::BadRequest.new("URLs must point to either a space or a tiddler")
    end
    [type, old, new]
  end

end
