class RedirectsController < ApplicationController
  def show
    redirect_to "/@#{params[:username]}"
  end
end
