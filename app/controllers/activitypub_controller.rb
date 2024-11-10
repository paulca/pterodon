class ActivitypubController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :verify_authenticity_token, only: [:inbox]
  before_action :set_default_response_format
  
  def actor
    @user = User.find_by!(username: params[:username])
    
    render json: {
      '@context': [
        'https://www.w3.org/ns/activitystreams',
        'https://w3id.org/security/v1'
      ],
      'id': actor_url(@user.username),
      'type': 'Person',
      'preferredUsername': @user.username,
      'inbox': inbox_url(@user.username),
      'outbox': outbox_url(@user.username),
      'followers': followers_url(@user.username),
      'following': following_url(@user.username),
      'publicKey': {
        'id': "#{actor_url(@user.username)}#main-key",
        'owner': actor_url(@user.username),
        'publicKeyPem': @user.public_key
      }
    }
  end

  def outbox
    @user = User.find_by!(username: params[:username])
    @posts = @user.posts.order(created_at: :desc).limit(20)
    
    render json: {
      '@context': 'https://www.w3.org/ns/activitystreams',
      'id': outbox_url(@user.username),
      'type': 'OrderedCollection',
      'totalItems': @posts.count,
      'orderedItems': @posts.map { |post| post_to_activity(post) }
    }
  end

  def inbox
    # Handle incoming activities
    activity = JSON.parse(request.body.read)
    # Process the activity based on its type
    # Implementation depends on what activities you want to support
  end

  private

  def post_to_activity(post)
    {
      '@context': 'https://www.w3.org/ns/activitystreams',
      'id': post_url(post),
      'type': 'Create',
      'actor': actor_url(post.user.username),
      'object': {
        'id': post_url(post),
        'type': 'Note',
        'published': post.created_at.iso8601,
        'attributedTo': actor_url(post.user.username),
        'content': post.content,
        'to': ['https://www.w3.org/ns/activitystreams#Public']
      }
    }
  end

  def set_default_response_format
    request.format = :json unless params[:format]
  end
end 