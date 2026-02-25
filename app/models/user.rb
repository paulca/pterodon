class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :posts
  has_many :remote_followers, dependent: :destroy

  encrypts :private_key

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  before_create :generate_activitypub_keys

  private

  def generate_activitypub_keys
    key = OpenSSL::PKey::RSA.new(2048)
    self.private_key = key.to_pem
    self.public_key = key.public_key.to_pem
  end
end
