module Bluesky
  class DeliverPostJob < ApplicationJob
    queue_as :default

    def perform(post_id)
      post = Post.find_by(id: post_id)
      return unless post

      return unless post.user.bluesky_configured?

      PostDeliveryService.new(post.user).deliver(post)
    end
  end
end
