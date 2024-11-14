class UsersController < ApplicationController
  allow_unauthenticated_access

  def show
    @user = User.find_by(username: params[:username])

    @posts = @user.posts
  end
end
