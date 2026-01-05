class Posts::UpvotesController < Blogs::BaseController
  include RequestHash

  rate_limit to: 10, within: 1.minute

  skip_before_action :authenticate
  before_action :load_post

  def create
    @post.upvotes.find_or_create_by!(hash_id: @hash_id)
    head :ok
  end


  private

    def load_post
      @post = @blog.posts.find_by!(token: params[:post_token])
    end
end
