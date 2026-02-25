module ActivityPub
  class WebfingerController < ApplicationController
    allow_unauthenticated_access
    skip_before_action :verify_authenticity_token

    def show
      resource = params[:resource]
      return head :bad_request if resource.blank?

      match = resource.match(/\Aacct:([^@]+)@(.+)\z/)
      return head :bad_request unless match

      username = match[1]
      domain = match[2]
      return head :not_found unless domain == request.host

      @user = User.find_by(username: username)
      return head :not_found unless @user

      render json: {
        subject: "acct:#{@user.username}@#{request.host}",
        aliases: [
          activity_pub_actor_url(@user.username)
        ],
        links: [
          {
            rel: 'self',
            type: 'application/activity+json',
            href: activity_pub_actor_url(@user.username)
          }
        ]
      }, content_type: 'application/jrd+json'
    end
  end
end
