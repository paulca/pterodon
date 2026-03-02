class ProfilesController < ApplicationController
  before_action :get_user

  def update
    if @user.update(user_params)
      redirect_to profile_path, notice: "User details updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def get_user
    @user = Current.user
  end

  def user_params
    permitted = params.require(:user).permit(:username, :email, :display_name, :avatar, :bsky_handle, :bsky_app_password)
    permitted.delete(:bsky_app_password) if permitted[:bsky_app_password].blank?
    permitted
  end
end
