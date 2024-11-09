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
    params.require(:user).permit(:username, :email)
  end
end
