module Bluesky
  class DeliverPostJob < ApplicationJob
    queue_as :default
    retry_on PostDeliveryService::DeliveryError, wait: :polynomially_longer, attempts: 5

    def perform(post_id)
      post = Post.find_by(id: post_id)
      return unless post

      return unless post.user.bluesky_configured?
      return if post.bsky_uri.present?

      PostDeliveryService.new(post.user).deliver(post)
    rescue PostDeliveryService::DeliveryError => e
      Rails.logger.error "Bluesky delivery failed for post #{post_id}: #{e.message}"
      raise
    end
  end
end
