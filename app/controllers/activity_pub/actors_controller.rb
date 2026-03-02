module ActivityPub
  class ActorsController < BaseController
    def show
      @user = User.find_by!(username: params[:username])

      actor = {
        '@context': [
          "https://www.w3.org/ns/activitystreams",
          "https://w3id.org/security/v1"
        ],
        'id': activity_pub_actor_url(@user.username),
        'type': "Person",
        'preferredUsername': @user.username,
        'name': @user.display_name_or_username,
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

      if @user.avatar.attached?
        actor[:icon] = {
          'type': "Image",
          'mediaType': @user.avatar.content_type,
          'url': url_for(@user.avatar)
        }
      end

      render json: actor
    end
  end
end
