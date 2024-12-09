class Posts::UpvotesController < ApplicationController
  include RequestHash

  rate_limit to: 5, within: 1.minute

  before_action :load_post

  def create
    @post.upvotes.find_or_create_by!(hash_id: @hash_id)
  end

  def destroy
    upvote = @post.upvotes.find_by(hash_id: @hash_id)
    if upvote
      upvote.destroy
    else
      head :not_found
    end
  end

  private

    def load_post
      @post = Post.find_by!(token: params[:post_id])
    end
end
