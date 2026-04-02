class Posts::Upvotes::StatusesController < Blogs::BaseController
  include RequestHash

  skip_before_action :authenticate

  def show
    tokens = Array(params[:tokens]).first(Blogs::PostsController::STREAM_PAGE_SIZE)
    posts = @blog.posts.where(token: tokens)
    upvoted_post_ids = Upvote.where(post: posts, hash_id: @hash_id).pluck(:post_id)

    render json: posts.to_h { |post| [ post.token, upvoted_post_ids.include?(post.id) ] }
  end
end
