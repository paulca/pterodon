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
      when 'Create'
        handle_create
      else
        Rails.logger.info "ProcessActivityJob: Ignoring unhandled activity type '#{@activity.type}' from #{@activity.actor}"
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
      actor_uri = @activity.actor

      case inner
      when Hash
        handle_undo_by_type(inner, actor_uri)
      when String
        # Some implementations send the object URI as a string instead of the full object.
        # Since we can't inspect the type, resolve by actor — if they're undoing anything,
        # the only thing we track is follows.
        remove_follower(actor_uri)
      else
        Rails.logger.warn "ProcessActivityJob: Unexpected Undo object type #{inner.class} from #{actor_uri}"
      end
    end

    def handle_undo_by_type(inner_object, actor_uri)
      case inner_object['type']
      when 'Follow'
        remove_follower(actor_uri)
      else
        Rails.logger.info "ProcessActivityJob: Ignoring Undo for type '#{inner_object['type']}' from #{actor_uri}"
      end
    end

    def remove_follower(actor_uri)
      follower = @user.remote_followers.find_by(actor_uri: actor_uri)
      if follower
        follower.destroy!
        Rails.logger.info "Removed follower #{actor_uri}"
      else
        Rails.logger.warn "ProcessActivityJob: Undo from #{actor_uri} but no follower record found"
      end
    end

    def handle_create
      note = @activity.object
      return unless note.is_a?(Hash) && note['type'] == 'Note'

      in_reply_to = note['inReplyTo']
      return unless in_reply_to.is_a?(String)

      post = find_local_post(in_reply_to)
      return unless post

      return unless note['id'].is_a?(String) && note['id'].present?

      sanitized_content = ActionController::Base.helpers.sanitize(note['content'])
      return if sanitized_content.blank?

      actor_name = fetch_actor_name(@activity.actor)

      post.remote_replies.find_or_create_by!(activity_uri: note['id']) do |reply|
        reply.actor_uri = @activity.actor
        reply.actor_name = actor_name
        reply.content = sanitized_content
        reply.published_at = parse_published_time(note['published'])
      end

      Rails.logger.info "Stored remote reply #{note['id']} on post #{post.id} from #{@activity.actor}"
    end

    def find_local_post(url)
      uri = URI.parse(url)
      local_host = URI.parse(Rails.application.routes.url_helpers.root_url).host
      return unless uri.host == local_host

      match = uri.path.match(%r{/activity_pub/([^/]+)/posts/(\d+)})
      return unless match

      @user.posts.find_by(id: match[2])
    rescue URI::InvalidURIError
      nil
    end

    def fetch_actor_name(actor_uri)
      actor = RemoteActorFetcher.call(actor_uri)
      actor['name'] || actor['preferredUsername'] || actor_uri
    rescue RemoteActorFetcher::FetchError => e
      Rails.logger.warn "ProcessActivityJob: Could not fetch actor name: #{e.message}"
      actor_uri
    end

    def parse_published_time(value)
      return Time.current if value.blank?
      Time.iso8601(value)
    rescue ArgumentError
      Rails.logger.warn "ProcessActivityJob: Failed to parse published date '#{value}'"
      Time.current
    end
  end
end
