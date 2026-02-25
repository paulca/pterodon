module ActivityPub
  module Serializers
    class Post
      def initialize(post)
        @post = post
      end

      def to_create_activity
        {
          '@context': "https://www.w3.org/ns/activitystreams",
          'id': "#{post_url}/activity",
          'type': "Create",
          'actor': actor_url,
          'published': @post.created_at.iso8601,
          'to': [ "https://www.w3.org/ns/activitystreams#Public" ],
          'cc': [ followers_url ],
          'object': to_note
        }
      end

      def to_note
        {
          'id': post_url,
          'type': "Note",
          'published': @post.created_at.iso8601,
          'url': post_url,
          'attributedTo': actor_url,
          'to': [ "https://www.w3.org/ns/activitystreams#Public" ],
          'cc': [ followers_url ],
          'content': content_html,
          'contentMap': { 'en': content_html },
          'attachment': [],
          'tag': []
        }
      end

      def to_delete_activity
        {
          '@context': "https://www.w3.org/ns/activitystreams",
          'id': "#{post_url}#delete",
          'type': "Delete",
          'actor': actor_url,
          'to': [ "https://www.w3.org/ns/activitystreams#Public" ],
          'object': {
            'id': post_url,
            'type': "Tombstone"
          }
        }
      end

      private

      def routes
        Rails.application.routes.url_helpers
      end

      def post_url
        routes.activity_pub_post_url(@post.user.username, @post)
      end

      def actor_url
        routes.activity_pub_actor_url(@post.user.username)
      end

      def followers_url
        routes.activity_pub_followers_url(@post.user.username)
      end

      def content_html
        "<p>#{ERB::Util.html_escape(@post.content)}</p>"
      end
    end
  end
end
