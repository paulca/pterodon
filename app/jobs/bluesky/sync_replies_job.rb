module Bluesky
  class SyncRepliesJob < ApplicationJob
    queue_as :default

    def perform
      User.find_each do |user|
        next unless user.bluesky_configured?

        ReplySyncService.new(user).sync_all
      rescue ReplySyncService::SyncError, Client::Error => e
        Rails.logger.error "Bluesky reply sync failed for user #{user.id}: #{e.message}"
      rescue StandardError => e
        Rails.logger.error "Unexpected error during Bluesky reply sync for user #{user.id}: #{e.class} - #{e.message}"
      end
    end
  end
end
