class RemoteReply < ApplicationRecord
  belongs_to :post

  validates :activity_uri, presence: true, uniqueness: true
  validates :actor_uri, presence: true
  validates :content, presence: true
end
