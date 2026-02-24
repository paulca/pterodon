module ActivityPub
  class ProcessActivityJob < ApplicationJob
    queue_as :default

    def perform(activity_hash, user_id)
      @activity = ActivityPub::Activity.new(activity_hash)
      @user = User.find(user_id)

      case @activity.type
      when 'Follow'
        handle_follow
      when 'Undo'
        handle_undo
      end
    end

    private

    def handle_follow
      follower_uri = @activity.actor
      actor = RemoteActorFetcher.call(follower_uri)

      inbox_url = actor["inbox"]
      shared_inbox_url = actor.dig("endpoints", "sharedInbox")

      follower = @user.remote_followers.find_or_create_by!(actor_uri: follower_uri) do |f|
        f.inbox_url = inbox_url
        f.shared_inbox_url = shared_inbox_url
      end

      # Update inbox URLs in case they changed
      follower.update!(inbox_url: inbox_url, shared_inbox_url: shared_inbox_url)

      # Send Accept(Follow) back to the follower's inbox
      accept_activity = {
        '@context': 'https://www.w3.org/ns/activitystreams',
        'id': "#{Rails.application.routes.url_helpers.activity_pub_actor_url(@user.username)}#accept-#{SecureRandom.hex(8)}",
        'type': 'Accept',
        'actor': Rails.application.routes.url_helpers.activity_pub_actor_url(@user.username),
        'object': @activity.to_h
      }

      DeliveryService.new(@user).deliver(inbox_url, accept_activity)

      Rails.logger.info "Accepted follow from #{follower_uri}"
    end

    def handle_undo
      inner = @activity.object

      case inner
      when Hash
        handle_undo_by_type(inner)
      when String
        # Some implementations send the object URI as a string
        Rails.logger.info "Received Undo with string object: #{inner}"
      end
    end

    def handle_undo_by_type(inner_object)
      case inner_object['type']
      when 'Follow'
        actor_uri = @activity.actor
        follower = @user.remote_followers.find_by(actor_uri: actor_uri)
        if follower
          follower.destroy!
          Rails.logger.info "Removed follower #{actor_uri}"
        end
      end
    end
  end
end
