class RemoteReply < ApplicationRecord
  ALLOWED_TAGS = %w[p br a strong em b i blockquote ul ol li code pre span].freeze
  ALLOWED_ATTRIBUTES = %w[href rel class].freeze

  belongs_to :post

  validates :activity_uri, presence: true, uniqueness: true
  validates :actor_uri, presence: true
  validates :content, presence: true
end
