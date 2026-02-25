require "resolv"
require "ipaddr"

module ActivityPub
  class UrlValidator
    class UnsafeUrlError < StandardError; end

    BLOCKED_RANGES = [
      IPAddr.new("0.0.0.0/8"),
      IPAddr.new("10.0.0.0/8"),
      IPAddr.new("100.64.0.0/10"),
      IPAddr.new("127.0.0.0/8"),
      IPAddr.new("169.254.0.0/16"),
      IPAddr.new("172.16.0.0/12"),
      IPAddr.new("192.0.0.0/24"),
      IPAddr.new("192.168.0.0/16"),
      IPAddr.new("::1/128"),
      IPAddr.new("fc00::/7"),
      IPAddr.new("fe80::/10")
    ].freeze

    def self.validate!(url)
      uri = URI.parse(url)

      unless uri.scheme == "https" || (Rails.env.development? && uri.scheme == "http")
        raise UnsafeUrlError, "URL must use HTTPS: #{url}"
      end

      raise UnsafeUrlError, "URL has no host: #{url}" if uri.host.blank?

      resolved = Resolv.getaddress(uri.host)
      ip = IPAddr.new(resolved)

      if BLOCKED_RANGES.any? { |range| range.include?(ip) }
        raise UnsafeUrlError, "URL resolves to private/reserved IP: #{url}"
      end

      uri
    rescue URI::InvalidURIError => e
      raise UnsafeUrlError, "Invalid URL: #{e.message}"
    rescue Resolv::ResolvError => e
      raise UnsafeUrlError, "Cannot resolve host for #{url}: #{e.message}"
    end
  end
end
