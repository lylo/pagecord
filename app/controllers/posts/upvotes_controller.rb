class Posts::UpvotesController < Blogs::BaseController
  include RequestHash

  rate_limit to: 10, within: 1.minute

  skip_before_action :authenticate
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
      @post = @blog.posts.find_by!(token: params[:post_token])
    end
end
