module ActivityPub
  class FollowersController < BaseController
    def index
      @user = User.find_by!(username: params[:username])

      render json: {
        '@context': "https://www.w3.org/ns/activitystreams",
        'id': activity_pub_followers_url(@user.username),
        'type': "OrderedCollection",
        'totalItems': @user.remote_followers.count
      }
    end
  end
end
