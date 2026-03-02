require "test_helper"

module Bluesky
  class DeliverDeleteJobTest < ActiveSupport::TestCase
    test "skips when user not found" do
      assert_nothing_raised do
        DeliverDeleteJob.perform_now("at://did:plc:abc/app.bsky.feed.post/123", -1)
      end
    end

    test "skips when user has no bluesky configured" do
      user = users(:two)
      assert_nothing_raised do
        DeliverDeleteJob.perform_now("at://did:plc:abc/app.bsky.feed.post/123", user.id)
      end
    end

    test "deletes post when user has bluesky configured" do
      user = users(:bsky_user)
      deleted_uri = nil

      fake_service = Object.new
      fake_service.define_singleton_method(:delete) { |uri| deleted_uri = uri }

      PostDeliveryService.stub(:new, fake_service) do
        DeliverDeleteJob.perform_now("at://did:plc:abc/app.bsky.feed.post/123", user.id)
      end

      assert_equal "at://did:plc:abc/app.bsky.feed.post/123", deleted_uri
    end
  end
end
