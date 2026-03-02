module Bluesky
  class Client
    class Error < StandardError; end

    BSKY_API = "https://bsky.social/xrpc".freeze

    def initialize(handle:, app_password:)
      @handle = handle
      @app_password = app_password
      @access_token = nil
      @did = nil
    end

    def authenticate!
      response = http.post(
        "#{BSKY_API}/com.atproto.server.createSession",
        json: { identifier: @handle, password: @app_password }
      )

      unless response.status.success?
        raise Error, "Authentication failed (HTTP #{response.status}): #{response.body.to_s.truncate(200)}"
      end

      data = JSON.parse(response.body.to_s)
      @access_token = data["accessJwt"]
      @did = data["did"]
    end

    def create_post(text, created_at: Time.current)
      ensure_authenticated!

      record = {
        "$type" => "app.bsky.feed.post",
        "text" => text,
        "createdAt" => created_at.iso8601
      }

      response = authenticated_http.post(
        "#{BSKY_API}/com.atproto.repo.createRecord",
        json: { repo: @did, collection: "app.bsky.feed.post", record: record }
      )

      unless response.status.success?
        raise Error, "Create post failed (HTTP #{response.status}): #{response.body.to_s.truncate(200)}"
      end

      data = JSON.parse(response.body.to_s)
      data["uri"]
    end

    def delete_post(at_uri)
      ensure_authenticated!

      repo, collection, rkey = parse_at_uri(at_uri)

      response = authenticated_http.post(
        "#{BSKY_API}/com.atproto.repo.deleteRecord",
        json: { repo: repo, collection: collection, rkey: rkey }
      )

      unless response.status.success?
        raise Error, "Delete post failed (HTTP #{response.status}): #{response.body.to_s.truncate(200)}"
      end

      true
    end

    def get_post_thread(at_uri)
      ensure_authenticated!

      response = authenticated_http.get(
        "#{BSKY_API}/app.bsky.feed.getPostThread",
        params: { uri: at_uri }
      )

      unless response.status.success?
        raise Error, "Get thread failed (HTTP #{response.status}): #{response.body.to_s.truncate(200)}"
      end

      JSON.parse(response.body.to_s)
    end

    private

    def http
      HTTP.timeout(connect: 5, write: 5, read: 10)
    end

    def authenticated_http
      http.auth("Bearer #{@access_token}")
    end

    def ensure_authenticated!
      raise Error, "Not authenticated. Call authenticate! first." unless @access_token
    end

    def parse_at_uri(at_uri)
      # at://did:plc:abc123/app.bsky.feed.post/rkey123
      match = at_uri.match(%r{\Aat://([^/]+)/([^/]+)/([^/]+)\z})
      raise Error, "Invalid AT URI: #{at_uri}" unless match

      [match[1], match[2], match[3]]
    end
  end
end
