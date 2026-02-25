class RemoteFollower < ApplicationRecord
  belongs_to :user

  validates :actor_uri, presence: true, uniqueness: { scope: :user_id }
  validates :inbox_url, presence: true
end
