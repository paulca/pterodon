module ActivityPub
  class HttpSignatureSigner
    def initialize(user)
      @user = user
      @private_key = OpenSSL::PKey::RSA.new(user.private_key)
    end

    # Returns a hash of headers to attach to the outgoing HTTP request.
    def sign(url, body:, method: :post)
      uri = URI.parse(url)
      date = Time.now.utc.httpdate
      digest = "SHA-256=#{Base64.strict_encode64(OpenSSL::Digest::SHA256.digest(body))}"

      headers_to_sign = {
        "(request-target)" => "#{method} #{uri.request_uri}",
        "host" => uri.host,
        "date" => date,
        "digest" => digest,
        "content-type" => "application/activity+json"
      }

      signed_string = headers_to_sign.map { |k, v| "#{k}: #{v}" }.join("\n")
      signature = Base64.strict_encode64(
        @private_key.sign(OpenSSL::Digest.new("SHA256"), signed_string)
      )

      key_id = "#{Rails.application.routes.url_helpers.activity_pub_actor_url(@user.username)}#main-key"
      header_names = headers_to_sign.keys.join(" ")

      {
        "Host" => uri.host,
        "Date" => date,
        "Digest" => digest,
        "Content-Type" => "application/activity+json",
        "Signature" => %(keyId="#{key_id}",algorithm="rsa-sha256",headers="#{header_names}",signature="#{signature}")
      }
    end
  end
end
