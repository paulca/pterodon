module ActivityPub
  class DeliverDeleteJob < ApplicationJob
    queue_as :default

    # We accept the activity JSON directly since the post is already destroyed
    # by the time this job runs.
    def perform(activity_json, user_id)
      user = User.find(user_id)
      return if user.remote_followers.none?

      activity = JSON.parse(activity_json)
      DeliveryService.new(user).deliver_to_followers(activity)
    end
  end
end
