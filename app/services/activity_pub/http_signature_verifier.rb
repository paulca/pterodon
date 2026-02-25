module ActivityPub
  class HttpSignatureVerifier
    class VerificationError < StandardError; end

    def initialize(request)
      @request = request
    end

    def verify!
      signature_header = @request.headers["Signature"]
      raise VerificationError, "Missing Signature header" if signature_header.blank?

      params = parse_signature_header(signature_header)
      key_id = params["keyId"]
      algorithm = params["algorithm"] || "rsa-sha256"
      headers = params["headers"]&.split(" ") || ["date"]
      signature = Base64.decode64(params["signature"])

      # Fetch the remote actor to get their public key
      actor_uri = key_id.sub(/#.*/, "")
      actor = RemoteActorFetcher.call(actor_uri)
      public_key_pem = actor.dig("publicKey", "publicKeyPem")
      raise VerificationError, "No public key found for #{actor_uri}" if public_key_pem.blank?

      public_key = OpenSSL::PKey::RSA.new(public_key_pem)

      # Reconstruct the signing string
      signing_string = headers.map do |header|
        case header
        when "(request-target)"
          "(request-target): #{@request.method.downcase} #{@request.original_fullpath}"
        when "host"
          "host: #{@request.host}"
        when "date"
          "date: #{@request.headers['Date']}"
        when "digest"
          "digest: #{@request.headers['Digest']}"
        when "content-type"
          "content-type: #{@request.content_type}"
        else
          "#{header}: #{@request.headers[header.titlecase]}"
        end
      end.join("\n")

      # Verify
      unless public_key.verify(OpenSSL::Digest.new("SHA256"), signature, signing_string)
        raise VerificationError, "Signature verification failed"
      end

      # Always verify body digest on POST requests
      if @request.post?
        raise VerificationError, "Missing Digest header on POST request" if @request.headers["Digest"].blank?
        verify_digest!
      end

      # Validate Date header to prevent replay attacks (allow 5 minute window)
      if @request.headers["Date"].present?
        begin
          request_time = Time.httpdate(@request.headers["Date"])
          if (Time.now.utc - request_time).abs > 300
            raise VerificationError, "Request Date is too old or too far in the future"
          end
        rescue ArgumentError
          raise VerificationError, "Invalid Date header format"
        end
      end

      true
    end

    private

    def parse_signature_header(header)
      header.scan(/(\w+)="([^"]*)"/).to_h
    end

    def verify_digest!
      body = @request.body.read
      @request.body.rewind
      expected = "SHA-256=#{Base64.strict_encode64(OpenSSL::Digest::SHA256.digest(body))}"
      unless ActiveSupport::SecurityUtils.secure_compare(expected, @request.headers["Digest"])
        raise VerificationError, "Digest mismatch"
      end
    end
  end
end
