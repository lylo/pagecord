class Admin::Moderation::BlogsController < Admin::BaseController
  include Pagy::Method

  def index
    @total_unreviewed = Blog.unreviewed.count
    @pagy, @blogs = pagy(
      Blog.unreviewed.order(created_at: :desc)
          .includes(:rich_text_bio, :navigation_items, user: :subscription),
      limit: 25
    )
    @post_counts = Post.kept.published.where(blog_id: @blogs.map(&:id)).group(:blog_id).count
  end
end
