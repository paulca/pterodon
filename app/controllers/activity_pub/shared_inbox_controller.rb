module ActivityPub
  class SharedInboxController < BaseController
    before_action :verify_http_signature!

    def create
      body = request.body.read
      request.body.rewind
      activity = ActivityPub::Activity.new(body)

      case activity.type
      when 'Follow'
        target_username = activity.object.split('/').last
        user = User.find_by!(username: target_username)
        ProcessActivityJob.perform_later(activity.to_h, user.id)
      when 'Undo'
        inner = activity.object
        if inner.is_a?(Hash) && inner['type'] == 'Follow'
          target_username = inner['object'].to_s.split('/').last
          user = User.find_by!(username: target_username)
          ProcessActivityJob.perform_later(activity.to_h, user.id)
        end
      end

      head :accepted
    rescue JSON::ParserError, KeyError
      head :bad_request
    end

    private

    def verify_http_signature!
      HttpSignatureVerifier.new(request).verify!
    rescue HttpSignatureVerifier::VerificationError => e
      Rails.logger.warn "HTTP Signature verification failed: #{e.message}"
      head :unauthorized
    end
  end
end
