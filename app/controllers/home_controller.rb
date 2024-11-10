class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    @posts = Post.order("created_at desc")
  end
end
