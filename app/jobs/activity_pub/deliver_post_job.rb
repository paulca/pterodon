module ActivityPub
  class DeliverPostJob < ApplicationJob
    queue_as :default

    def perform(post_id)
      post = Post.find_by(id: post_id)
      return unless post

      user = post.user
      return if user.remote_followers.none?

      activity = Serializers::Post.new(post).to_create_activity
      DeliveryService.new(user).deliver_to_followers(activity)
    end
  end
end
