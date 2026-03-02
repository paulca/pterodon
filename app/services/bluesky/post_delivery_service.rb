module Bluesky
  class PostDeliveryService
    class DeliveryError < StandardError; end

    def initialize(user)
      @user = user
      @client = Client.new(handle: user.bsky_handle, app_password: user.bsky_app_password)
    end

    def deliver(post)
      @client.authenticate!
      bsky_uri = @client.create_post(post.content, created_at: post.created_at)
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
  end
end
