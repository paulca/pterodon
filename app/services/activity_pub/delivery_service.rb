module ActivityPub
  class DeliveryService
    def initialize(user)
      @user = user
      @signer = HttpSignatureSigner.new(user)
    end

    # Delivers a signed ActivityPub payload to a remote inbox.
    def deliver(inbox_url, payload)
      body = payload.is_a?(String) ? payload : payload.to_json
      headers = @signer.sign(inbox_url, body: body)

      response = HTTP.headers(headers).post(inbox_url, body: body)

      unless response.status.success? || response.status.code == 202
        Rails.logger.warn "ActivityPub delivery to #{inbox_url} failed: #{response.status} #{response.body}"
      end

      response
    end

    # Delivers a payload to all unique inbox URLs for a user's followers.
    # Prefers shared_inbox_url when available to reduce requests.
    def deliver_to_followers(payload)
      inbox_urls = @user.remote_followers
        .pluck(:inbox_url, :shared_inbox_url)
        .map { |inbox, shared| shared.presence || inbox }
        .uniq

      inbox_urls.each do |inbox_url|
        deliver(inbox_url, payload)
      end
    end
  end
end
