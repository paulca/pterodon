module ActivityPub
  class ActorsController < BaseController
    def show
      @user = User.find_by!(username: params[:username])

      render json: {
        '@context': [
          'https://www.w3.org/ns/activitystreams',
          'https://w3id.org/security/v1'
        ],
        'id': activity_pub_actor_url(@user.username),
        'type': 'Person',
        'preferredUsername': @user.username,
        'name': @user.username,
        'inbox': activity_pub_inbox_url(@user.username),
        'outbox': activity_pub_outbox_url(@user.username),
        'followers': activity_pub_followers_url(@user.username),
        'following': activity_pub_following_index_url(@user.username),
        'url': activity_pub_actor_url(@user.username),
        'publicKey': {
          'id': "#{activity_pub_actor_url(@user.username)}#main-key",
          'owner': activity_pub_actor_url(@user.username),
          'publicKeyPem': @user.public_key
        },
        'endpoints': {
          'sharedInbox': activity_pub_shared_inbox_url
        }
      }
    end
  end
end
