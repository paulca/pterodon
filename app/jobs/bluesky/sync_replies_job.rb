module Bluesky
  class SyncRepliesJob < ApplicationJob
    queue_as :default

    def perform
      User.find_each do |user|
        next unless user.bluesky_configured?

        ReplySyncService.new(user).sync_all
      rescue ReplySyncService::SyncError => e
        Rails.logger.error "Bluesky reply sync failed for user #{user.id}: #{e.message}"
      end
    end
  end
end
