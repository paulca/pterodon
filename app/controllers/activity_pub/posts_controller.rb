module ActivityPub
  class PostsController < BaseController
    def show
      @user = User.find_by!(username: params[:username])
      @post = @user.posts.find(params[:id])

      render json: {
        '@context': "https://www.w3.org/ns/activitystreams",
        'id': activity_pub_post_url(@user.username, @post),
        'type': "Note",
        'published': @post.created_at.iso8601,
        'attributedTo': activity_pub_actor_url(@user.username),
        'content': "<p>#{ERB::Util.html_escape(@post.content)}</p>",
        'to': [ "https://www.w3.org/ns/activitystreams#Public" ],
        'cc': [ activity_pub_followers_url(@user.username) ]
      }
    end
  end
end
