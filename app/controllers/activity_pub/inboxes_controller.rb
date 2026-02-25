module ActivityPub
  class InboxesController < BaseController
    before_action :verify_http_signature!

    def create
      @user = User.find_by!(username: params[:username])
      body = request.body.read
      request.body.rewind
      activity = ActivityPub::Activity.new(body)

      ProcessActivityJob.perform_later(activity.to_h, @user.id)

      head :accepted
    rescue JSON::ParserError => e
      Rails.logger.warn "Inbox: Invalid JSON: #{e.message}"
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
