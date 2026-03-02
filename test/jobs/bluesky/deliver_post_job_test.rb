require "test_helper"

module Bluesky
  class DeliverPostJobTest < ActiveSupport::TestCase
    test "skips when post not found" do
      assert_nothing_raised do
        DeliverPostJob.perform_now(-1)
      end
    end

    test "skips when user has no bluesky configured" do
      post = posts(:two) # user :two has no bluesky credentials
      assert_nothing_raised do
        DeliverPostJob.perform_now(post.id)
      end
    end

    test "delivers post when user has bluesky configured" do
      user = users(:bsky_user)
      delivered_post = nil

      fake_service = Object.new
      fake_service.define_singleton_method(:deliver) { |post| delivered_post = post }

      PostDeliveryService.stub(:new, fake_service) do
        post = user.posts.create!(content: "Test bluesky post")
        DeliverPostJob.perform_now(post.id)
        assert_equal post, delivered_post
      end
    end
  end
end
