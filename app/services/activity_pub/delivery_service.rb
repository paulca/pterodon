module ActivityPub
  class DeliveryService
    class DeliveryError < StandardError; end

    def initialize(user)
      @user = user
      @signer = HttpSignatureSigner.new(user)
    end

    # Delivers a signed ActivityPub payload to a remote inbox.
    # Raises DeliveryError on failure.
    def deliver(inbox_url, payload)
      body = payload.is_a?(String) ? payload : payload.to_json
      headers = @signer.sign(inbox_url, body: body)

      response = HTTP.timeout(connect: 5, write: 5, read: 10)
        .headers(headers)
        .post(inbox_url, body: body)

      unless response.status.success? || response.status.code == 202
        raise DeliveryError, "HTTP #{response.status} from #{inbox_url}: #{response.body.to_s.truncate(200)}"
      end

      response
    rescue HTTP::Error, SocketError, OpenSSL::SSL::SSLError, Errno::ECONNREFUSED => e
      raise DeliveryError, "#{e.class} delivering to #{inbox_url}: #{e.message}"
    end

    # Delivers a payload to all unique inbox URLs for a user's followers.
    # Continues delivering to remaining inboxes if one fails.
    def deliver_to_followers(payload)
      inbox_urls = @user.remote_followers
        .pluck(:inbox_url, :shared_inbox_url)
        .map { |inbox, shared| shared.presence || inbox }
        .uniq

      failures = []
      inbox_urls.each do |inbox_url|
        deliver(inbox_url, payload)
      rescue DeliveryError => e
        failures << inbox_url
        Rails.logger.error "ActivityPub delivery failed: #{e.message}"
      end

      if failures.any?
        Rails.logger.error "ActivityPub delivery failed for #{failures.size}/#{inbox_urls.size} inboxes"
      end
    end
  end
end
