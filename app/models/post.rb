class Post < ApplicationRecord
  belongs_to :user

  after_create_commit :deliver_to_followers
  after_destroy_commit :deliver_delete_to_followers

  private

  def deliver_to_followers
    ActivityPub::DeliverPostJob.perform_later(id)
  end

  def deliver_delete_to_followers
    activity = ActivityPub::Serializers::Post.new(self).to_delete_activity
    ActivityPub::DeliverDeleteJob.perform_later(activity.to_json, user_id)
  end
end
