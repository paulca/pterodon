module ActivityPub
  class FollowingController < BaseController
    def index
      @user = User.find_by!(username: params[:username])

      render json: {
        '@context': "https://www.w3.org/ns/activitystreams",
        'id': activity_pub_following_index_url(@user.username),
        'type': "OrderedCollection",
        'totalItems': 0,
        'orderedItems': []
      }
    end
  end
end
