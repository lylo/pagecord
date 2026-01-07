class Admin::ModerationController < AdminController
  include Pagy::Backend

  def index
    @pagy, @posts = pagy(
      Post.with_discarded
          .moderation_flagged
          .published
          .joins(blog: :user)
          .where(users: { discarded_at: nil })
          .includes(:content_moderation, blog: :user)
          .order("content_moderations.moderated_at DESC"),
      limit: 25
    )
    @pending_count = Post.moderation_pending.count
  end

  def show
    @post = Post.with_discarded.includes(:content_moderation, blog: :user).find(params[:id])
  end

  def dismiss
    @post = Post.with_discarded.find(params[:id])
    @post.undiscard if @post.discarded?
    @post.content_moderation&.update!(status: :clean)
    redirect_to admin_moderation_index_path, notice: "Post restored and marked as reviewed"
  end

  def discard
    @post = Post.find(params[:id])
    @post.discard!
    redirect_to admin_moderation_index_path, notice: "Post discarded"
  end
end
