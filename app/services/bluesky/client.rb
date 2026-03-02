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

      data = parse_json(response.body.to_s, context: "authenticate!")
      @access_token = data["accessJwt"]
      @did = data["did"]

      raise Error, "Authentication response missing accessJwt" if @access_token.blank?
      raise Error, "Authentication response missing did" if @did.blank?
    rescue HTTP::Error, SocketError, OpenSSL::SSL::SSLError,
           Errno::ECONNREFUSED, Errno::ETIMEDOUT, Errno::EHOSTUNREACH,
           Errno::ENETUNREACH, Errno::ECONNRESET, Errno::EPIPE => e
      raise Error, "#{e.class} during authenticate!: #{e.message}"
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

      data = parse_json(response.body.to_s, context: "create_post")
      uri = data["uri"]
      raise Error, "Create post response missing 'uri'" if uri.blank?
      uri
    rescue HTTP::Error, SocketError, OpenSSL::SSL::SSLError,
           Errno::ECONNREFUSED, Errno::ETIMEDOUT, Errno::EHOSTUNREACH,
           Errno::ENETUNREACH, Errno::ECONNRESET, Errno::EPIPE => e
      raise Error, "#{e.class} during create_post: #{e.message}"
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
    rescue HTTP::Error, SocketError, OpenSSL::SSL::SSLError,
           Errno::ECONNREFUSED, Errno::ETIMEDOUT, Errno::EHOSTUNREACH,
           Errno::ENETUNREACH, Errno::ECONNRESET, Errno::EPIPE => e
      raise Error, "#{e.class} during delete_post: #{e.message}"
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

      parse_json(response.body.to_s, context: "get_post_thread")
    rescue HTTP::Error, SocketError, OpenSSL::SSL::SSLError,
           Errno::ECONNREFUSED, Errno::ETIMEDOUT, Errno::EHOSTUNREACH,
           Errno::ENETUNREACH, Errno::ECONNRESET, Errno::EPIPE => e
      raise Error, "#{e.class} during get_post_thread: #{e.message}"
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

    def parse_json(body, context:)
      JSON.parse(body)
    rescue JSON::ParserError => e
      raise Error, "#{context}: invalid JSON response: #{body.truncate(200)} (#{e.message})"
    end

    def parse_at_uri(at_uri)
      # at://did:plc:abc123/app.bsky.feed.post/rkey123
      match = at_uri.match(%r{\Aat://([^/]+)/([^/]+)/([^/]+)\z})
      raise Error, "Invalid AT URI: #{at_uri}" unless match

      [ match[1], match[2], match[3] ]
    end
  end
end
