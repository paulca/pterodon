module ActivityPub
  class SharedInboxController < BaseController
    before_action :verify_http_signature!

    def create
      body = request.body.read
      request.body.rewind
      activity = ActivityPub::Activity.new(body)

      user = resolve_target_user(activity)
      if user
        ProcessActivityJob.perform_later(activity.to_h, user.id)
      else
        Rails.logger.info "SharedInbox: Could not resolve target user for #{activity.type} from #{activity.actor}"
      end

      head :accepted
    rescue JSON::ParserError => e
      Rails.logger.warn "SharedInbox: Invalid JSON: #{e.message}"
      head :bad_request
    end

    private

    def resolve_target_user(activity)
      case activity.type
      when 'Follow'
        extract_user_from_actor_uri(activity.object)
      when 'Undo'
        inner = activity.object
        if inner.is_a?(Hash) && inner['type'] == 'Follow'
          extract_user_from_actor_uri(inner['object'])
        end
      end
    end

    def extract_user_from_actor_uri(object)
      uri = case object
            when String then object
            when Hash then object['id']
            end
      return unless uri.is_a?(String)

      match = URI.parse(uri).path.match(%r{/activity_pub/([^/]+)/actor})
      User.find_by(username: match[1]) if match
    end

    def verify_http_signature!
      HttpSignatureVerifier.new(request).verify!
    rescue HttpSignatureVerifier::VerificationError => e
      Rails.logger.warn "HTTP Signature verification failed: #{e.message}"
      head :unauthorized
    end
  end
end
