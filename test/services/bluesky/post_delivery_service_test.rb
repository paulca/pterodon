require "test_helper"

module Bluesky
  class PostDeliveryServiceTest < ActiveSupport::TestCase
    setup do
      @user = users(:bsky_user)
      @post = posts(:one)
    end

    test "deliver calls client authenticate and create_post then saves bsky_uri" do
      delivered = { authenticated: false, text: nil, created_at: nil }

      fake_client = Object.new
      fake_client.define_singleton_method(:authenticate!) { delivered[:authenticated] = true }
      fake_client.define_singleton_method(:create_post) do |text, created_at:|
        delivered[:text] = text
        delivered[:created_at] = created_at
        "at://did:plc:abc/app.bsky.feed.post/123"
      end

      Client.stub(:new, fake_client) do
        PostDeliveryService.new(@user).deliver(@post)
      end

      assert delivered[:authenticated]
      assert_equal @post.content, delivered[:text]
      assert_equal "at://did:plc:abc/app.bsky.feed.post/123", @post.reload.bsky_uri
    end

    test "deliver wraps client errors in DeliveryError" do
      fake_client = Object.new
      fake_client.define_singleton_method(:authenticate!) { raise Client::Error, "auth failed" }

      Client.stub(:new, fake_client) do
        assert_raises(PostDeliveryService::DeliveryError) do
          PostDeliveryService.new(@user).deliver(@post)
        end
      end
    end

    test "delete calls client authenticate and delete_post" do
      deleted_uri = nil

      fake_client = Object.new
      fake_client.define_singleton_method(:authenticate!) { nil }
      fake_client.define_singleton_method(:delete_post) { |uri| deleted_uri = uri; true }

      Client.stub(:new, fake_client) do
        PostDeliveryService.new(@user).delete("at://did:plc:abc/app.bsky.feed.post/123")
      end

      assert_equal "at://did:plc:abc/app.bsky.feed.post/123", deleted_uri
    end
  end
end
