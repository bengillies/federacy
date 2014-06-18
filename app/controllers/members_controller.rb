class MembersController < ApplicationController
  respond_to :html, :json

  wrap_parameters :member, include: %w(user_id permission)

  before_action :authenticate_user!, :find_space

  def index
    @members = @space.space_users
  end

  def show
    redirect_to profile_path(@space.users.find(params[:id]))
  end

  def create
    return forbidden("add members to", :space) unless current_user.manage_space?(@space)
    @member = User.find_by_email member_params[:email]
    return unprocessable_entity unless @member
    @space_user = @member.space_users.build space_id: @space.id, access: member_params[:access]

    respond_with @space_user do |format|
      if @space_user.save
        format.json { created :space_user, @space_user, space_member_path(@space, @member) }
      else
        format.json { unprocessable_entity }
      end
      format.html { redirect_to space_members_path(@space) }
    end
  end

  def update
    return forbidden("update members in", :space) unless current_user.manage_space?(@space)
    @space_user = @space.space_users.find_by_user_id(params[:id])
    return unprocessable_entity unless @space_user
    if member_params["access"] != "admin" && current_user.id == @space_user.user_id
      return forbidden("remove admin access for youself from", :space) unless @space.space_users.admin.count > 1
    end

    @space_user.update member_params

    respond_with @space_user do |format|
      if @space.save
        format.json { no_content }
      else
        format.json { unprocessable_entity }
      end
      format.html { redirect_to space_members_path(@space) }
    end
  end

  def destroy
    return forbidden("delete members from", :space) unless current_user.manage_space?(@space)
    @space_user = @space.space_users.find_by_user_id(params[:id])
    return unprocessable_entity unless @space_user
    return forbidden("Remove yourself from", :space) if current_user.id == @space_user.user_id

    respond_with @space_user do |format|
      if @space_user.destroy
        format.json { no_content }
      else
        format.json { unprocessable_entity }
      end
      format.html { redirect_to space_members_path(@space) }
    end
  end

  protected

  def find_space
    @space = current_user.spaces.find(params[:space_id])
  end

  def member_params
    params.require(:member).permit(:email, :access)
  end
end
