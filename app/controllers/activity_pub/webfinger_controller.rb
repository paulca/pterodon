module ActivityPub
  class WebfingerController < ActionController::Base
    def show
      resource = params[:resource]
      return head :not_found if resource.blank?

      username = resource.split('@').first.sub('acct:', '')
      @user = User.find_by!(username: username)

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
