module ActivityPub
  class Delivery
    def initialize(post)
      @post = post
    end
    
    def deliver_to_followers
      @post.user.followers.each do |follower|
        deliver_to_inbox(follower.inbox_url, create_activity)
      end
    end
    
    private
    
    def create_activity
      {
        '@context': 'https://www.w3.org/ns/activitystreams',
        'id': "#{post_url(@post)}/activity",
        'type': 'Create',
        'actor': actor_url(@post.user.username),
        'object': {
          'id': post_url(@post),
          'type': 'Note',
          'published': @post.created_at.iso8601,
          'attributedTo': actor_url(@post.user.username),
          'content': @post.content,
          'to': ['https://www.w3.org/ns/activitystreams#Public']
        }
      }
    end
    
    def deliver_to_inbox(inbox_url, activity)
      response = HTTP
        .headers(request_headers)
        .post(inbox_url, json: activity)
        
      unless response.status.success?
        Rails.logger.error "Failed to deliver to #{inbox_url}: #{response.status} - #{response.body}"
      end
    rescue HTTP::Error => e
      Rails.logger.error "HTTP delivery error to #{inbox_url}: #{e.message}"
    end

    def request_headers
      {
        'Content-Type' => 'application/activity+json',
        'Accept' => 'application/activity+json',
        'User-Agent' => "#{Rails.application.class.module_parent_name}/#{Rails.application.config.version}"
      }
    end
  end
end 