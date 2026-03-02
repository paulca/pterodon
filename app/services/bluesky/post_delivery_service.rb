module Bluesky
  class PostDeliveryService
    class DeliveryError < StandardError; end

    def initialize(user)
      @user = user
      @client = Client.new(handle: user.bsky_handle, app_password: user.bsky_app_password)
    end

    MAX_GRAPHEMES = 300

    def deliver(post)
      @client.authenticate!
      text = truncate_graphemes(post.content)
      bsky_uri = @client.create_post(text, created_at: post.created_at)
      post.update_column(:bsky_uri, bsky_uri)
    rescue Client::Error => e
      raise DeliveryError, "Bluesky delivery failed for post #{post.id}: #{e.message}"
    rescue HTTP::Error, SocketError, OpenSSL::SSL::SSLError,
           Errno::ECONNREFUSED, Errno::ETIMEDOUT, Errno::EHOSTUNREACH,
           Errno::ENETUNREACH, Errno::ECONNRESET, Errno::EPIPE => e
      raise DeliveryError, "#{e.class} delivering to Bluesky: #{e.message}"
    end

    def delete(bsky_uri)
      @client.authenticate!
      @client.delete_post(bsky_uri)
    rescue Client::Error => e
      raise DeliveryError, "Bluesky delete failed for #{bsky_uri}: #{e.message}"
    rescue HTTP::Error, SocketError, OpenSSL::SSL::SSLError,
           Errno::ECONNREFUSED, Errno::ETIMEDOUT, Errno::EHOSTUNREACH,
           Errno::ENETUNREACH, Errno::ECONNRESET, Errno::EPIPE => e
      raise DeliveryError, "#{e.class} deleting from Bluesky: #{e.message}"
    end

    private

    def truncate_graphemes(text)
      graphemes = text.grapheme_clusters
      return text if graphemes.length <= MAX_GRAPHEMES

      graphemes.first(MAX_GRAPHEMES - 1).join + "\u2026"
    end
  end
end
