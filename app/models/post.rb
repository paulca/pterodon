class Post < ApplicationRecord
  belongs_to :user
  
  after_create :broadcast_to_followers
  
  private
  
  def broadcast_to_followers
    ActivityPub::Delivery.new(self).deliver_to_followers
  end
end
