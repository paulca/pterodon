module Bluesky
  class DeliverDeleteJob < ApplicationJob
    queue_as :default
    retry_on PostDeliveryService::DeliveryError, wait: :polynomially_longer, attempts: 10

    # We accept bsky_uri + user_id since the post is already destroyed
    # by the time this job runs.
    def perform(bsky_uri, user_id)
      user = User.find_by(id: user_id)
      return unless user&.bluesky_configured?

      PostDeliveryService.new(user).delete(bsky_uri)
    rescue PostDeliveryService::DeliveryError => e
      Rails.logger.error "Bluesky delete failed for uri=#{bsky_uri} user=#{user_id}: #{e.message}"
      raise
    end
  end
end
