class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :posts
  has_many :remote_followers, dependent: :destroy
  has_one_attached :avatar

  encrypts :private_key
  encrypts :bsky_app_password

  def display_name_or_username
    display_name.presence || username
  end

  def bluesky_configured?
    bsky_handle.present? && bsky_app_password.present?
  end

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :bsky_handle, with: ->(h) { h.strip.delete_prefix("@") }

  before_create :generate_activitypub_keys

  private

  def generate_activitypub_keys
    key = OpenSSL::PKey::RSA.new(2048)
    self.private_key = key.to_pem
    self.public_key = key.public_key.to_pem
  end
end
