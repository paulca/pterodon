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

    test "extract_facets detects URLs" do
      client = Client.new(handle: "test.bsky.social", app_password: "test")
      facets = client.send(:extract_facets, "Check out https://paulca.com for more")

      assert_equal 1, facets.length
      assert_equal "app.bsky.richtext.facet#link", facets[0]["features"][0]["$type"]
      assert_equal "https://paulca.com", facets[0]["features"][0]["uri"]
      assert_equal 10, facets[0]["index"]["byteStart"]
      assert_equal 28, facets[0]["index"]["byteEnd"]
    end

    test "extract_facets detects multiple URLs" do
      client = Client.new(handle: "test.bsky.social", app_password: "test")
      facets = client.send(:extract_facets, "See https://a.com and https://b.com")

      assert_equal 2, facets.length
      assert_equal "https://a.com", facets[0]["features"][0]["uri"]
      assert_equal "https://b.com", facets[1]["features"][0]["uri"]
    end

    test "extract_facets detects hashtags" do
      client = Client.new(handle: "test.bsky.social", app_password: "test")
      facets = client.send(:extract_facets, "Hello #world")

      assert_equal 1, facets.length
      assert_equal "app.bsky.richtext.facet#tag", facets[0]["features"][0]["$type"]
      assert_equal "world", facets[0]["features"][0]["tag"]
      assert_equal 6, facets[0]["index"]["byteStart"]
      assert_equal 12, facets[0]["index"]["byteEnd"]
    end

    test "extract_facets handles UTF-8 byte offsets correctly" do
      client = Client.new(handle: "test.bsky.social", app_password: "test")
      # emoji is 4 bytes in UTF-8
      facets = client.send(:extract_facets, "\u{1F600} https://example.com")

      assert_equal 1, facets.length
      assert_equal 5, facets[0]["index"]["byteStart"] # 4 bytes for emoji + 1 space
      assert_equal 24, facets[0]["index"]["byteEnd"]   # 5 + 19 bytes for URL
    end

    test "extract_facets returns empty array for plain text" do
      client = Client.new(handle: "test.bsky.social", app_password: "test")
      facets = client.send(:extract_facets, "Just a plain text post")
      assert_empty facets
    end
  end
end
