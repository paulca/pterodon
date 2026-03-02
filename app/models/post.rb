class Post < ApplicationRecord
  belongs_to :user
  has_many :remote_replies, dependent: :destroy

  after_create_commit :deliver_to_followers
  after_create_commit :deliver_to_bluesky
  after_destroy_commit :deliver_delete_to_followers
  after_destroy_commit :deliver_delete_to_bluesky

  private

  def deliver_to_followers
    ActivityPub::DeliverPostJob.perform_later(id)
  end

  def deliver_delete_to_followers
    activity = ActivityPub::Serializers::Post.new(self).to_delete_activity
    ActivityPub::DeliverDeleteJob.perform_later(activity.to_json, user_id)
  end

  def deliver_to_bluesky
    return unless user.bluesky_configured?

    Bluesky::DeliverPostJob.perform_later(id)
  end

  def deliver_delete_to_bluesky
    return unless user.bluesky_configured? && bsky_uri.present?

    Bluesky::DeliverDeleteJob.perform_later(bsky_uri, user_id)
  end
end
