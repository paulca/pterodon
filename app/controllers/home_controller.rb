class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    @posts = Post.includes(:remote_replies, user: { avatar_attachment: :blob }).order("created_at desc")
  end
end
