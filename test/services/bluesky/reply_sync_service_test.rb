require "test_helper"

module Bluesky
  class ReplySyncServiceTest < ActiveSupport::TestCase
    setup do
      @user = users(:bsky_user)
      @post = posts(:one)
      @post.update_column(:bsky_uri, "at://did:plc:abc/app.bsky.feed.post/123")
    end

    test "sync_post creates remote replies from thread" do
      thread_response = {
        "thread" => {
          "post" => { "uri" => "at://did:plc:abc/app.bsky.feed.post/123" },
          "replies" => [
            {
              "post" => {
                "uri" => "at://did:plc:xyz/app.bsky.feed.post/reply1",
                "author" => { "did" => "did:plc:xyz", "handle" => "replier.bsky.social", "displayName" => "Replier" },
                "record" => { "text" => "Nice post!", "createdAt" => "2026-03-01T12:00:00Z" }
              },
              "replies" => []
            }
          ]
        }
      }

      fake_client = Object.new
      fake_client.define_singleton_method(:authenticate!) { nil }
      fake_client.define_singleton_method(:get_post_thread) { |_uri| thread_response }

      Client.stub(:new, fake_client) do
        assert_difference "RemoteReply.count", 1 do
          ReplySyncService.new(@user).sync_post(@post)
        end
      end

      reply = @post.remote_replies.last
      assert_equal "at://did:plc:xyz/app.bsky.feed.post/reply1", reply.activity_uri
      assert_equal "did:plc:xyz", reply.actor_uri
      assert_equal "Replier", reply.actor_name
      assert_equal "Nice post!", reply.content
    end

    test "sync_post does not create duplicates" do
      @post.remote_replies.create!(
        activity_uri: "at://did:plc:xyz/app.bsky.feed.post/reply1",
        actor_uri: "did:plc:xyz",
        actor_name: "Replier",
        content: "Nice post!"
      )

      thread_response = {
        "thread" => {
          "post" => { "uri" => @post.bsky_uri },
          "replies" => [
            {
              "post" => {
                "uri" => "at://did:plc:xyz/app.bsky.feed.post/reply1",
                "author" => { "did" => "did:plc:xyz", "handle" => "replier.bsky.social", "displayName" => "Replier" },
                "record" => { "text" => "Nice post!", "createdAt" => "2026-03-01T12:00:00Z" }
              },
              "replies" => []
            }
          ]
        }
      }

      fake_client = Object.new
      fake_client.define_singleton_method(:authenticate!) { nil }
      fake_client.define_singleton_method(:get_post_thread) { |_uri| thread_response }

      Client.stub(:new, fake_client) do
        assert_no_difference "RemoteReply.count" do
          ReplySyncService.new(@user).sync_post(@post)
        end
      end
    end

    test "sync_all skips posts without bsky_uri" do
      @post.update_column(:bsky_uri, nil)

      authenticated = false
      fake_client = Object.new
      fake_client.define_singleton_method(:authenticate!) { authenticated = true }

      Client.stub(:new, fake_client) do
        ReplySyncService.new(@user).sync_all
      end

      assert_not authenticated, "Should not authenticate when no posts have bsky_uri"
    end
  end
end
