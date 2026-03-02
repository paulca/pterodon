module Bluesky
  class ReplySyncService
    class SyncError < StandardError; end

    def initialize(user)
      @user = user
      @client = Client.new(handle: user.bsky_handle, app_password: user.bsky_app_password)
      @authenticated = false
    end

    def sync_all
      posts = @user.posts.where.not(bsky_uri: nil)
      return if posts.none?

      ensure_authenticated!

      posts.find_each do |post|
        sync_post(post)
      rescue Client::Error, SyncError => e
        Rails.logger.error "Bluesky reply sync failed for post #{post.id}: #{e.message}"
      end
    end

    def sync_post(post)
      ensure_authenticated!

      thread = @client.get_post_thread(post.bsky_uri)
      replies = thread.dig("thread", "replies") || []

      extract_replies(replies, post)
    rescue Client::Error => e
      raise SyncError, "Failed to sync replies for post #{post.id}: #{e.message}"
    end

    private

    def ensure_authenticated!
      return if @authenticated

      @client.authenticate!
      @authenticated = true
    end

    MAX_DEPTH = 20

    def extract_replies(replies, post, depth: 0)
      if depth > MAX_DEPTH
        Rails.logger.warn "Bluesky reply sync: max depth reached for post #{post.id}, truncating"
        return
      end

      replies.each do |reply_node|
        reply_post = reply_node["post"]
        next unless reply_post

        uri = reply_post["uri"]
        author = reply_post.dig("author", "displayName") || reply_post.dig("author", "handle")
        actor_uri = reply_post.dig("author", "did")
        content = reply_post.dig("record", "text")
        created_at = reply_post.dig("record", "createdAt")

        next if uri.blank? || actor_uri.blank? || content.blank?

        begin
          post.remote_replies.find_or_create_by!(activity_uri: uri) do |r|
            r.actor_uri = actor_uri
            r.actor_name = author
            r.content = content
            r.published_at = parse_time(created_at)
          end
        rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
          Rails.logger.error "Bluesky reply sync: failed to save reply #{uri} for post #{post.id}: #{e.message}"
          next
        end

        # Recurse into nested replies
        nested = reply_node["replies"] || []
        extract_replies(nested, post, depth: depth + 1)
      end
    end

    def parse_time(value)
      return Time.current if value.blank?

      Time.iso8601(value)
    rescue ArgumentError
      Time.current
    end
  end
end
