module Bluesky
  class DeliverDeleteJob < ApplicationJob
    queue_as :default

    # We accept bsky_uri + user_id since the post is already destroyed
    # by the time this job runs.
    def perform(bsky_uri, user_id)
      user = User.find_by(id: user_id)
      return unless user&.bluesky_configured?

      PostDeliveryService.new(user).delete(bsky_uri)
    end
  end
end
