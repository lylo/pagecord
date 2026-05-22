class Posts::Upvotes::StatusController < Blogs::BaseController
  include RequestHash

  skip_before_action :authenticate

  def show
    post = @blog.posts.find_by!(token: params[:post_token])
    upvoted = post.upvotes.exists?(hash_id: @hash_id)
    render json: { upvoted: upvoted }
  end
end
