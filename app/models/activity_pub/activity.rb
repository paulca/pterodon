module ActivityPub
  class Activity
    attr_reader :payload

    def initialize(json_payload)
      @payload = json_payload.is_a?(String) ? JSON.parse(json_payload) : json_payload
    end

    def type
      payload["type"]
    end

    def actor
      payload["actor"]
    end

    def object
      payload["object"]
    end

    def to_h
      payload
    end
  end
end
