class Admin::Moderation::SpamController < AdminController
  include Pagy::Backend

  def index
    @pagy, @spam_detections = pagy(
      SpamDetection.needs_review
                   .joins(blog: :user)
                   .where(users: { discarded_at: nil })
                   .includes(blog: :user)
                   .order(detected_at: :desc),
      limit: 25
    )
    @total_unreviewed = SpamDetection.needs_review.count
  end

  def show
    @spam_detection = SpamDetection.includes(blog: :user).find(params[:id])
    @blog = @spam_detection.blog
  end

  def dismiss
    @spam_detection = SpamDetection.find(params[:id])
    @spam_detection.update!(status: :clean, reviewed_at: Time.current)
    redirect_to admin_moderation_spam_index_path, notice: "Blog marked as clean"
  end

  def confirm
    @spam_detection = SpamDetection.find(params[:id])
    @spam_detection.mark_as_reviewed!

    user = @spam_detection.blog.user
    DestroyUserJob.perform_later(user.id, spam: true)

    redirect_to admin_moderation_spam_index_path, notice: "Spam confirmed and user will be discarded"
  end
end
