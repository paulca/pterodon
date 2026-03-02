require "test_helper"

module Bluesky
  class SyncRepliesJobTest < ActiveSupport::TestCase
    test "syncs replies for configured users" do
      synced_users = []

      fake_service = Object.new
      fake_service.define_singleton_method(:sync_all) { nil }

      original_new = ReplySyncService.method(:new)
      ReplySyncService.stub(:new, ->(*args) { synced_users << args.first; fake_service }) do
        SyncRepliesJob.perform_now
      end

      # Only bsky_user has bluesky configured
      assert_includes synced_users.map(&:username), "bskyuser"
      synced_users.each do |user|
        assert user.bluesky_configured?, "Should only sync configured users"
      end
    end

    test "continues syncing when one user fails" do
      fake_service = Object.new
      fake_service.define_singleton_method(:sync_all) { raise ReplySyncService::SyncError, "test error" }

      ReplySyncService.stub(:new, fake_service) do
        assert_nothing_raised do
          SyncRepliesJob.perform_now
        end
      end
    end
  end
end
