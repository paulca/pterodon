require "test_helper"

module Bluesky
  class ClientTest < ActiveSupport::TestCase
    test "parse_at_uri extracts components correctly" do
      client = Client.new(handle: "test.bsky.social", app_password: "test")
      repo, collection, rkey = client.send(:parse_at_uri, "at://did:plc:abc123/app.bsky.feed.post/rkey456")
      assert_equal "did:plc:abc123", repo
      assert_equal "app.bsky.feed.post", collection
      assert_equal "rkey456", rkey
    end

    test "parse_at_uri raises on invalid URI" do
      client = Client.new(handle: "test.bsky.social", app_password: "test")
      assert_raises(Client::Error) { client.send(:parse_at_uri, "invalid-uri") }
    end

    test "create_post raises when not authenticated" do
      client = Client.new(handle: "test.bsky.social", app_password: "test")
      assert_raises(Client::Error) { client.create_post("Hello") }
    end

    test "delete_post raises when not authenticated" do
      client = Client.new(handle: "test.bsky.social", app_password: "test")
      assert_raises(Client::Error) { client.delete_post("at://did:plc:abc/app.bsky.feed.post/123") }
    end

    test "get_post_thread raises when not authenticated" do
      client = Client.new(handle: "test.bsky.social", app_password: "test")
      assert_raises(Client::Error) { client.get_post_thread("at://did:plc:abc/app.bsky.feed.post/123") }
    end
  end
end
