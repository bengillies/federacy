class ProfilesController < ApplicationController
  respond_to :html, :json

  def show
    @user = User.find params[:id]
  end
end
