class WebfingerController < ApplicationController
  allow_unauthenticated_access
  def show
    resource = params[:resource]
    username = resource.split('@').first.sub('acct:', '')
    
    @user = User.find_by!(username: username)
    
    render json: {
      subject: resource,
      links: [
        {
          rel: 'self',
          type: 'application/activity+json',
          href: actor_url(@user.username)
        }
      ]
    }
  end
end 