class Admin::Moderation::ContentController < Admin::BaseController
  include Pagy::Method

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
  end

  def show
    @post = Post.with_discarded.includes(:content_moderation, blog: :user).find_by!(token: params[:id])
  end
end
