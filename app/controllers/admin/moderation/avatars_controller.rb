class Admin::Moderation::AvatarsController < AdminController
  include Pagy::Method

  def index
    @pagy, @avatar_moderations = pagy(
      AvatarModeration.needs_review
                      .joins(blog: :user)
                      .where(users: { discarded_at: nil })
                      .includes(blog: :user)
                      .order(moderated_at: :desc),
      limit: 25
    )
    @total_unreviewed = AvatarModeration.needs_review.count
  end

  def dismiss
    @avatar_moderation = AvatarModeration.find(params[:id])
    @avatar_moderation.mark_as_reviewed!
    redirect_to admin_moderation_avatars_path, notice: "Avatar kept and marked as reviewed"
  end

  def remove
    @avatar_moderation = AvatarModeration.find(params[:id])
    @avatar_moderation.blog.avatar.purge
    @avatar_moderation.mark_as_reviewed!
    redirect_to admin_moderation_avatars_path, notice: "Avatar removed"
  end
end
