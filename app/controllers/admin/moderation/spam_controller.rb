class Admin::Moderation::SpamController < Admin::BaseController
  include Pagy::Method

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
end
