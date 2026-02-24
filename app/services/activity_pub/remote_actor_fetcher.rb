module ActivityPub
  class RemoteActorFetcher
    # Fetches and parses a remote actor's JSON-LD document.
    # Caches the result for 1 hour to avoid repeated lookups.
    def self.call(actor_uri)
      Rails.cache.fetch("activitypub:actor:#{actor_uri}", expires_in: 1.hour) do
        response = HTTP.headers(
          "Accept" => "application/activity+json, application/ld+json"
        ).get(actor_uri)

        raise "Failed to fetch actor #{actor_uri}: #{response.status}" unless response.status.success?

        JSON.parse(response.body.to_s)
      end
    end
  end
end
