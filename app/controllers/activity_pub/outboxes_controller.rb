module ActivityPub
  class OutboxesController < BaseController
    def show
      @user = User.find_by!(username: params[:username])
      @posts = @user.posts.order(created_at: :desc).limit(20)

      render json: {
        '@context': [
          'https://www.w3.org/ns/activitystreams',
          'https://w3id.org/security/v1'
        ],
        'id': activity_pub_outbox_url(@user.username),
        'type': 'OrderedCollectionPage',
        'totalItems': @posts.count,
        'first': activity_pub_outbox_url(@user.username),
        'last': activity_pub_outbox_url(@user.username),
        'orderedItems': @posts.map { |post| create_activity_for_post(post) }
      }
    end

    private

    def create_activity_for_post(post)
      {
        'id': "#{activity_pub_post_url(post.user.username, post)}/activity",
        'type': 'Create',
        'actor': activity_pub_actor_url(post.user.username),
        'published': post.created_at.iso8601,
        'to': [ 'https://www.w3.org/ns/activitystreams#Public' ],
        'cc': [ activity_pub_followers_url(post.user.username) ],
        'object': {
          'id': activity_pub_post_url(post.user.username, post),
          'type': 'Note',
          'summary': nil,
          'inReplyTo': nil,
          'published': post.created_at.iso8601,
          'url': activity_pub_post_url(post.user.username, post),
          'attributedTo': activity_pub_actor_url(post.user.username),
          'to': [ 'https://www.w3.org/ns/activitystreams#Public' ],
          'cc': [ activity_pub_followers_url(post.user.username) ],
          'sensitive': false,
          'content': "<p>#{ERB::Util.html_escape(post.content)}</p>",
          'contentMap': { 'en': "<p>#{ERB::Util.html_escape(post.content)}</p>" },
          'attachment': [],
          'tag': []
        }
      }
    end
  end
end
