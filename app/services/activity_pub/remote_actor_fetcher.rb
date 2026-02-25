module ActivityPub
  class RemoteActorFetcher
    class FetchError < StandardError; end

    # Fetches and parses a remote actor's JSON-LD document.
    # Caches the result for 1 hour to avoid repeated lookups.
    def self.call(actor_uri, force_refresh: false)
      cache_key = "activitypub:actor:#{actor_uri}"
      Rails.cache.delete(cache_key) if force_refresh

      Rails.cache.fetch(cache_key, expires_in: 1.hour) do
        UrlValidator.validate!(actor_uri)

        response = HTTP.timeout(connect: 5, read: 10)
          .headers("Accept" => "application/activity+json, application/ld+json")
          .get(actor_uri)

        raise FetchError, "HTTP #{response.status} fetching actor #{actor_uri}" unless response.status.success?

        JSON.parse(response.body.to_s)
      end
    rescue HTTP::Error, SocketError, OpenSSL::SSL::SSLError, Errno::ECONNREFUSED => e
      raise FetchError, "Network error fetching actor #{actor_uri}: #{e.class} - #{e.message}"
    rescue JSON::ParserError => e
      raise FetchError, "Invalid JSON from actor #{actor_uri}: #{e.message}"
    rescue UrlValidator::UnsafeUrlError => e
      raise FetchError, e.message
    end
  end
end
