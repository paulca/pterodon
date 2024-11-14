class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    authenticate_with_http_basic do |username, password|
      user = User.find_by(username: username)
      redirect_to "#{request.protocol}null@#{request.host}#{request.port ? ":#{request.port}" : ""}/@#{user.username}" if user.present?
    end
    @posts = Post.order("created_at desc")
  end
end
